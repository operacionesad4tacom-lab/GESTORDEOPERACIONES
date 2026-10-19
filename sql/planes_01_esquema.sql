-- ═══════════════════════════════════════════════════════════════
-- SIGO — Control de Planes Operativos
-- 01 · Esquema de datos
-- Ejecutar en Supabase → SQL Editor (antes de 02 y 03)
-- Todas las tablas del módulo usan el prefijo po_
-- Convención: NULL = "No especificado" (nunca se rellena con supuestos)
-- ═══════════════════════════════════════════════════════════════

begin;

-- ─── Unidades / destacamentos ──────────────────────────────────
create table if not exists po_unidades (
  id               uuid primary key default gen_random_uuid(),
  nombre           text not null unique,
  sigla            text not null unique,
  propia           boolean not null default true,   -- false: especializadas o externas (OS7, OS9...)
  umbral_personal  int,                              -- sobrecarga diaria (NULL = sin umbral)
  umbral_vehiculos int,
  orden            int not null default 0,
  activa           boolean not null default true
);

-- Campos del módulo en la tabla de usuarios existente (no altera la autenticación)
alter table users add column if not exists planes_rol text
  check (planes_rol in ('admin_operaciones','jefe_destacamento','consulta'));
alter table users add column if not exists planes_unidad_id uuid references po_unidades(id);

-- ─── Configuración ─────────────────────────────────────────────
create table if not exists po_config (
  clave       text primary key,
  valor       text not null,
  descripcion text
);

-- ─── Planes ────────────────────────────────────────────────────
create table if not exists po_planes (
  id                       uuid primary key default gen_random_uuid(),
  tipo                     text not null check (tipo in
                             ('plan_operativo','plan_abreviado','orden_doe','emergencia',
                              'mesa_coordinacion','evento_preparacion')),
  numero                   text,
  titulo                   text not null,
  emisor                   text check (emisor in
                             ('direccion_nacional','zona','prefectura','subprefectura_fronteriza',
                              'comisaria','seremi','otro')),
  emisor_detalle           text,
  fecha_emision            date,
  mision                   text,
  inicio                   timestamptz,
  termino                  timestamptz,
  hasta_nueva_orden        boolean not null default false,
  recurrencia              text,                    -- ej.: "Lunes y martes, 2 semanas al mes"
  jefe_servicio            text,
  supervisor               text,
  prioridad                text not null default 'normal'
                             check (prioridad in ('normal','importante','critica')),
  personal_total_declarado int,                     -- total que declara el documento (puede no estar desglosado)
  observaciones            text,
  revision                 text not null default 'por_revisar'
                             check (revision in ('por_revisar','confirmado')),
  confirmado_por           uuid references users(id),
  confirmado_en            timestamptz,
  cerrado                  boolean not null default false,
  cerrado_por              uuid references users(id),
  cerrado_en               timestamptz,
  es_plantilla             boolean not null default false,
  plantilla_origen_id      uuid references po_planes(id) on delete set null,
  plan_asociado_id         uuid references po_planes(id) on delete set null, -- evento en preparación → plan que lo cubre
  creado_por               uuid references users(id) default auth.uid(),
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  check (termino is null or inicio is null or termino >= inicio)
);

-- NCU de origen y adiciones (historial por documento)
create table if not exists po_ncu (
  id             uuid primary key default gen_random_uuid(),
  plan_id        uuid not null references po_planes(id) on delete cascade,
  ncu            text not null,
  fecha          date,
  resumen        text,
  es_origen      boolean not null default false,
  cambios        jsonb,                             -- [{campo, antes, despues}] al registrar una adición
  registrado_por uuid references users(id) default auth.uid(),
  created_at     timestamptz not null default now()
);

create table if not exists po_etapas (
  id       uuid primary key default gen_random_uuid(),
  plan_id  uuid not null references po_planes(id) on delete cascade,
  nombre   text not null,
  inicio   timestamptz,
  termino  timestamptz,
  lugar    text,
  tactica  text,
  orden    int not null default 0
);

-- Facción / punto de control
create table if not exists po_facciones (
  id                  uuid primary key default gen_random_uuid(),
  plan_id             uuid not null references po_planes(id) on delete cascade,
  etapa_id            uuid references po_etapas(id) on delete set null,
  nombre              text not null,
  lugar               text,
  unidad_cargo_id     uuid references po_unidades(id),
  jefe_faccion        text,
  apoyo_instituciones text[] not null default '{}',
  apoyo_detalle       text,
  observaciones       text,
  orden               int not null default 0
);

-- Recursos por unidad dentro de una facción (NULL = no especificado)
create table if not exists po_recursos (
  id         uuid primary key default gen_random_uuid(),
  plan_id    uuid not null references po_planes(id) on delete cascade,
  faccion_id uuid not null references po_facciones(id) on delete cascade,
  unidad_id  uuid references po_unidades(id),
  -- personal por grado
  crl int, tcrl int, may int, cap int, tte int, pns int, pni int,
  total_personal int generated always as (
    coalesce(crl,0)+coalesce(tcrl,0)+coalesce(may,0)+coalesce(cap,0)+
    coalesce(tte,0)+coalesce(pns,0)+coalesce(pni,0)) stored,
  -- medios logísticos
  fz int, rp int, ab int, ac int, m int, tt int, tl int, rm int, ap int, can int,
  nota       text
);

-- Ventanas concretas de servicio (cada fecha / turno es una fila).
-- Una fila sin facción representa el plan o etapa completa (ej.: emergencias).
create table if not exists po_servicios (
  id                 uuid primary key default gen_random_uuid(),
  plan_id            uuid not null references po_planes(id) on delete cascade,
  faccion_id         uuid references po_facciones(id) on delete cascade,
  etapa_id           uuid references po_etapas(id) on delete set null,
  turno              text,
  inicio             timestamptz not null,
  termino            timestamptz not null,
  presentacion       timestamptz,
  lugar_presentacion text,
  hora_por_confirmar boolean not null default false,
  institucion        text,
  observaciones      text,
  check (termino >= inicio)
);

create table if not exists po_plazos (
  id                  uuid primary key default gen_random_uuid(),
  plan_id             uuid not null references po_planes(id) on delete cascade,
  tipo                text not null check (tipo in
                        ('acuse_recibo','labor','evaluacion','informe_semanal','remision_plan','otro')),
  descripcion         text,
  vence               timestamptz,
  al_termino_servicio boolean not null default false, -- "inmediatamente una vez finalizado el servicio"
  destinatario        text,
  formato             text,
  estado              text not null default 'pendiente' check (estado in ('pendiente','cumplido')),
  ncu_cumplimiento    text,
  cumplido_en         timestamptz,
  cumplido_por        uuid references users(id)
);

-- Contradicciones entre fuentes, pendientes de resolver
create table if not exists po_contradicciones (
  id           uuid primary key default gen_random_uuid(),
  plan_id      uuid not null references po_planes(id) on delete cascade,
  campo        text not null,
  valor_a      text,
  fuente_a     text,
  valor_b      text,
  fuente_b     text,
  resuelta     boolean not null default false,
  resolucion   text,
  resuelta_por uuid references users(id),
  resuelta_en  timestamptz,
  created_at   timestamptz not null default now()
);

-- Indicadores personalizados por plan
create table if not exists po_indicadores (
  id          uuid primary key default gen_random_uuid(),
  plan_id     uuid not null references po_planes(id) on delete cascade,
  nombre      text not null,
  tipo        text not null default 'numero' check (tipo in ('numero','porcentaje')),
  numerador   text,
  denominador text,
  descripcion text,
  orden       int not null default 0
);

-- Labor desarrollada (una por fecha de servicio y facción)
create table if not exists po_labor (
  id                     uuid primary key default gen_random_uuid(),
  plan_id                uuid not null references po_planes(id) on delete cascade,
  servicio_id            uuid references po_servicios(id) on delete set null,
  faccion_id             uuid references po_facciones(id) on delete set null,
  unidad_id              uuid references po_unidades(id),
  fecha                  date not null,
  jefe_servicio          text,
  hora_inicio_real       time,
  hora_termino_real      time,
  indicadores            jsonb not null default '{}',
  indicadores_plan       jsonb not null default '{}',
  novedades              text,
  estado_personal_medios text,
  registrado_por         uuid references users(id) default auth.uid(),
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

-- Auditoría (creación, edición, confirmación, borrado)
create table if not exists po_auditoria (
  id          bigserial primary key,
  tabla       text not null,
  registro_id uuid,
  plan_id     uuid,
  accion      text not null,
  usuario_id  uuid,
  antes       jsonb,
  despues     jsonb,
  en          timestamptz not null default now()
);

-- ─── Índices ───────────────────────────────────────────────────
create index if not exists idx_po_planes_revision  on po_planes(revision);
create index if not exists idx_po_planes_fechas    on po_planes(inicio, termino);
create index if not exists idx_po_planes_numero    on po_planes(numero);
create index if not exists idx_po_ncu_ncu          on po_ncu(ncu);
create index if not exists idx_po_ncu_plan         on po_ncu(plan_id);
create index if not exists idx_po_etapas_plan      on po_etapas(plan_id);
create index if not exists idx_po_facciones_plan   on po_facciones(plan_id);
create index if not exists idx_po_facciones_unidad on po_facciones(unidad_cargo_id);
create index if not exists idx_po_recursos_faccion on po_recursos(faccion_id);
create index if not exists idx_po_recursos_unidad  on po_recursos(unidad_id);
create index if not exists idx_po_servicios_plan   on po_servicios(plan_id);
create index if not exists idx_po_servicios_fechas on po_servicios(inicio, termino);
create index if not exists idx_po_plazos_plan      on po_plazos(plan_id);
create index if not exists idx_po_plazos_vence     on po_plazos(estado, vence);
create index if not exists idx_po_contra_plan      on po_contradicciones(plan_id);
create index if not exists idx_po_labor_plan       on po_labor(plan_id, fecha);
create index if not exists idx_po_auditoria_plan   on po_auditoria(plan_id, en);

-- ─── updated_at automático ─────────────────────────────────────
create or replace function po_touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_po_planes_touch on po_planes;
create trigger trg_po_planes_touch before update on po_planes
  for each row execute function po_touch_updated_at();
drop trigger if exists trg_po_labor_touch on po_labor;
create trigger trg_po_labor_touch before update on po_labor
  for each row execute function po_touch_updated_at();

-- ─── Auditoría automática ──────────────────────────────────────
create or replace function po_auditar() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  fila   jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  accion text  := lower(tg_op);
begin
  -- IF anidado: PL/pgSQL no garantiza cortocircuito y old.revision solo existe en po_planes
  if tg_table_name = 'po_planes' and tg_op = 'UPDATE' then
    if old.revision = 'por_revisar' and new.revision = 'confirmado' then
      accion := 'confirmacion';
    end if;
  end if;
  insert into po_auditoria (tabla, registro_id, plan_id, accion, usuario_id, antes, despues)
  values (
    tg_table_name,
    (fila->>'id')::uuid,
    case when tg_table_name = 'po_planes' then (fila->>'id')::uuid else (fila->>'plan_id')::uuid end,
    accion,
    auth.uid(),
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) end
  );
  return null;
end $$;

do $$
declare t text;
begin
  foreach t in array array['po_planes','po_ncu','po_etapas','po_facciones','po_recursos',
                           'po_servicios','po_plazos','po_contradicciones','po_indicadores','po_labor']
  loop
    execute format('drop trigger if exists trg_%1$s_audit on %1$s', t);
    execute format('create trigger trg_%1$s_audit after insert or update or delete on %1$s
                    for each row execute function po_auditar()', t);
  end loop;
end $$;

-- ─── Datos base ────────────────────────────────────────────────
insert into po_config (clave, valor, descripcion) values
  ('umbral_planes_dia', '4', 'N° de planes con facciones activas en un día a partir del cual se marca "alta carga"')
on conflict (clave) do nothing;

insert into po_unidades (nombre, sigla, propia, orden) values
  ('4ta Comisaría Chacalluta (F)', '4ta Com.',        true,  1),
  ('SIP 4ta Comisaría',            'SIP 4ta Com.',    true,  2),
  ('Tenencia Chungará (F)',        'Tcia. Chungará',  true,  3),
  ('Tenencia Visviri (F)',         'Tcia. Visviri',   true,  4),
  ('Retén Chucuyo (F)',            'Retén Chucuyo',   true,  5),
  ('Retén Tacora',                 'Retén Tacora',    true,  6),
  ('Retén Guallatire',             'Retén Guallatire',true,  7),
  ('Retén Chilcaya',               'Retén Chilcaya',  true,  8),
  ('Tenencia Carretera',           'Tcia. Carretera', false, 20),
  ('OS7 Arica',                    'OS7',             false, 21),
  ('OS9',                          'OS9',             false, 22)
on conflict (nombre) do nothing;

commit;
