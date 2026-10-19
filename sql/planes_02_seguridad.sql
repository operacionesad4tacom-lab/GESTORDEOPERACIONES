-- ═══════════════════════════════════════════════════════════════
-- SIGO — Control de Planes Operativos
-- 02 · Seguridad (RLS por rol y unidad)
-- Ejecutar después de 01_esquema.sql
--
-- Roles del módulo (users.planes_rol). Si está vacío se deriva de users.rol:
--   ADMIN / OPERACIONES → admin_operaciones   (todo)
--   resto               → consulta            (solo lectura)
--   jefe_destacamento   → se asigna a mano    (ve su unidad y registra labor)
-- ═══════════════════════════════════════════════════════════════

begin;

-- ─── Funciones de apoyo ────────────────────────────────────────
create or replace function po_rol() returns text
language sql stable security definer set search_path = public as $$
  select coalesce(u.planes_rol,
                  case when u.rol in ('ADMIN','OPERACIONES') then 'admin_operaciones' else 'consulta' end)
  from users u
  where u.id = auth.uid() and coalesce(u.activo, true)
$$;

create or replace function po_mi_unidad() returns uuid
language sql stable security definer set search_path = public as $$
  select planes_unidad_id from users where id = auth.uid()
$$;

create or replace function po_es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(po_rol() = 'admin_operaciones', false)
$$;

-- ¿Puede el usuario actual ver este plan?
--  · Administrador: todos (incluida la bandeja "Por revisar").
--  · Consulta: planes confirmados.
--  · Jefe de destacamento: planes confirmados donde su unidad está a cargo o aporta recursos.
create or replace function po_puede_ver_plan(p_plan uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from po_planes pl
    where pl.id = p_plan
      and (
        po_es_admin()
        or (pl.revision = 'confirmado' and (
              po_rol() = 'consulta'
              or (po_rol() = 'jefe_destacamento' and po_mi_unidad() is not null and (
                    exists (select 1 from po_facciones f
                            where f.plan_id = pl.id and f.unidad_cargo_id = po_mi_unidad())
                 or exists (select 1 from po_recursos r
                            where r.plan_id = pl.id and r.unidad_id = po_mi_unidad())))))
      )
  )
$$;

-- ─── Proteger los campos del módulo en users ───────────────────
-- Evita que un usuario se asigne a sí mismo el rol o la unidad del módulo.
create or replace function po_proteger_campos_usuario() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (new.planes_rol is distinct from old.planes_rol
      or new.planes_unidad_id is distinct from old.planes_unidad_id)
     and auth.uid() is not null and not po_es_admin() then
    raise exception 'Solo el Administrador de Operaciones puede cambiar el rol o la unidad del módulo de planes';
  end if;
  return new;
end $$;

drop trigger if exists trg_po_proteger_usuario on users;
create trigger trg_po_proteger_usuario before update on users
  for each row execute function po_proteger_campos_usuario();

-- ─── RLS ───────────────────────────────────────────────────────
alter table po_unidades        enable row level security;
alter table po_config          enable row level security;
alter table po_planes          enable row level security;
alter table po_ncu             enable row level security;
alter table po_etapas          enable row level security;
alter table po_facciones       enable row level security;
alter table po_recursos        enable row level security;
alter table po_servicios       enable row level security;
alter table po_plazos          enable row level security;
alter table po_contradicciones enable row level security;
alter table po_indicadores     enable row level security;
alter table po_labor           enable row level security;
alter table po_auditoria       enable row level security;

grant select, insert, update, delete on
  po_unidades, po_config, po_planes, po_ncu, po_etapas, po_facciones, po_recursos,
  po_servicios, po_plazos, po_contradicciones, po_indicadores, po_labor
  to authenticated;
grant select on po_auditoria to authenticated;

-- Limpia políticas previas del módulo (permite re-ejecutar el script)
do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies
           where schemaname = 'public' and tablename like 'po\_%'
  loop
    execute format('drop policy if exists %I on %I', r.policyname, r.tablename);
  end loop;
end $$;

-- Catálogos: lectura para todos los autenticados, escritura solo admin
create policy po_unidades_leer   on po_unidades for select to authenticated using (true);
create policy po_unidades_admin  on po_unidades for all    to authenticated using (po_es_admin()) with check (po_es_admin());
create policy po_config_leer     on po_config   for select to authenticated using (true);
create policy po_config_admin    on po_config   for all    to authenticated using (po_es_admin()) with check (po_es_admin());

-- Planes
create policy po_planes_leer   on po_planes for select to authenticated using (po_puede_ver_plan(id));
create policy po_planes_crear  on po_planes for insert to authenticated with check (po_es_admin());
create policy po_planes_editar on po_planes for update to authenticated using (po_es_admin()) with check (po_es_admin());
create policy po_planes_borrar on po_planes for delete to authenticated using (po_es_admin());

-- Tablas hijas: misma visibilidad que el plan; edición solo admin
do $$
declare t text;
begin
  foreach t in array array['po_ncu','po_etapas','po_facciones','po_recursos','po_servicios',
                           'po_plazos','po_contradicciones','po_indicadores']
  loop
    execute format('create policy %1$s_leer  on %1$s for select to authenticated using (po_puede_ver_plan(plan_id))', t);
    execute format('create policy %1$s_admin on %1$s for all    to authenticated using (po_es_admin()) with check (po_es_admin())', t);
  end loop;
end $$;

-- El jefe de destacamento puede marcar como cumplido el plazo de labor de un plan que ve
create policy po_plazos_labor_jefe on po_plazos for update to authenticated
  using      (po_rol() = 'jefe_destacamento' and tipo = 'labor' and po_puede_ver_plan(plan_id))
  with check (po_rol() = 'jefe_destacamento' and tipo = 'labor' and po_puede_ver_plan(plan_id));

-- Labor: admin y consulta ven todo lo visible; el jefe ve y registra lo de su unidad
create policy po_labor_leer on po_labor for select to authenticated
  using (po_puede_ver_plan(plan_id)
         and (po_rol() in ('admin_operaciones','consulta') or unidad_id = po_mi_unidad()));
create policy po_labor_crear on po_labor for insert to authenticated
  with check (po_es_admin()
              or (po_rol() = 'jefe_destacamento' and unidad_id = po_mi_unidad() and po_puede_ver_plan(plan_id)));
create policy po_labor_editar on po_labor for update to authenticated
  using      (po_es_admin() or (po_rol() = 'jefe_destacamento' and unidad_id = po_mi_unidad()))
  with check (po_es_admin() or (po_rol() = 'jefe_destacamento' and unidad_id = po_mi_unidad()));
create policy po_labor_borrar on po_labor for delete to authenticated using (po_es_admin());

-- Auditoría: solo lectura para el administrador (se escribe por trigger)
create policy po_auditoria_leer on po_auditoria for select to authenticated using (po_es_admin());

commit;
