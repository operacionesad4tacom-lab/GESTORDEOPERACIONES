-- ═══════════════════════════════════════════════════════════════
-- SIGO — Control de Planes Operativos
-- 05 · Operación "Centinela 2.0" — PAO Tráfico de Armas
--      Plan Operativo N°102 Prefectura Arica (20.10.2026) + traza DOE NCU 265083048
-- Ejecutar en Supabase → SQL Editor.
--  · Si el plan no existe, lo crea con su traza DOE.
--  · Si ya existe (versión anterior de este script), le agrega el detalle del Plan N°102
--    (facciones, horarios, recursos, contradicciones) conservando su estado de revisión.
--  · Si ya tiene el detalle, no hace nada.
-- Fuente del detalle: "Plan Operativo Centinela 2.0.pdf" (Plan N°102, 9 páginas).
-- ═══════════════════════════════════════════════════════════════

begin;
set local time zone 'America/Santiago';

-- Unidades que participan en el Plan N°102 y aún no estaban registradas
insert into po_unidades (nombre, sigla, propia, orden) values
  ('Retén Alcérreca (F)',             'Retén Alcérreca', true,  9),
  ('Plana Mayor Prefectura Arica',    'P.M. Pref. Arica', false, 30),
  ('1ra Comisaría Arica',             '1ra Com.',        false, 31),
  ('SIP 1ra Comisaría Arica',         'SIP 1ra Com.',    false, 32),
  ('3ra Comisaría Arica',             '3ra Com.',        false, 33),
  ('SIP 3ra Comisaría Arica',         'SIP 3ra Com.',    false, 34),
  ('6ta Comisaría Chinchorro Norte',  '6ta Com.',        false, 35),
  ('SIP 6ta Comisaría Chinchorro',    'SIP 6ta Com.',    false, 36),
  ('Sección Dron Arica',              'Sec. Dron',       false, 37)
on conflict do nothing;

do $$
declare
  u_com uuid; u_tac uuid; u_alc uuid; u_cuy uuid; u_vis uuid; u_car uuid; u_os7 uuid; u_os9 uuid;
  u_pm uuid; u_1c uuid; u_1s uuid; u_3c uuid; u_3s uuid; u_6c uuid; u_6s uuid; u_dron uuid;
  p uuid; f uuid;
  d date;
begin
  select id into u_com  from po_unidades where sigla = '4ta Com.';
  select id into u_tac  from po_unidades where sigla = 'Retén Tacora';
  select id into u_alc  from po_unidades where sigla = 'Retén Alcérreca';
  select id into u_cuy  from po_unidades where sigla = 'Retén Chucuyo';
  select id into u_vis  from po_unidades where sigla = 'Tcia. Visviri';
  select id into u_car  from po_unidades where sigla = 'Tcia. Carretera';
  select id into u_os7  from po_unidades where sigla = 'OS7';
  select id into u_os9  from po_unidades where sigla = 'OS9';
  select id into u_pm   from po_unidades where sigla = 'P.M. Pref. Arica';
  select id into u_1c   from po_unidades where sigla = '1ra Com.';
  select id into u_1s   from po_unidades where sigla = 'SIP 1ra Com.';
  select id into u_3c   from po_unidades where sigla = '3ra Com.';
  select id into u_3s   from po_unidades where sigla = 'SIP 3ra Com.';
  select id into u_6c   from po_unidades where sigla = '6ta Com.';
  select id into u_6s   from po_unidades where sigla = 'SIP 6ta Com.';
  select id into u_dron from po_unidades where sigla = 'Sec. Dron';

  select plan_id into p from po_ncu where ncu = '265083048' limit 1;

  -- ─── Crear el plan y su traza DOE si no existe ───────────────
  if p is null then
    insert into po_planes (tipo, titulo, revision) values ('plan_operativo', 'Operación "Centinela 2.0"', 'por_revisar')
    returning id into p;

    insert into po_ncu (plan_id, ncu, es_origen, resumen, fecha) values
      (p, '261693284', true,  'CICPOL: solicitud del Ministerio de Seguridad Pública; levantamiento de información según ficha PAO Armas, a más tardar el 05.09.2026', null),
      (p, '261704140', false, 'DNOS: remitir los antecedentes solicitados por el CICPOL; plazo 04.09.2026 17:00', null),
      (p, '261707118', false, 'DICDINCAR dispone a la repartición especializada (OS9) el levantamiento de información; plazo 04.09.2026 09:00', null),
      (p, '261991704', false, 'OS9: operaciones simultáneas "Marlin", "Dron", "Volcán" y "Centinela 2.0" entre el 26 y 30.10.2026; sugiere consolidar la ficha en la DNOS', null),
      (p, '261993443', false, 'DICDINCAR solicita a la DNOS evaluar recabar y consolidar los antecedentes del despliegue institucional', null),
      (p, '262064110', false, 'DICDINCAR: documento remitido a la DNOS', null),
      (p, '262065475', false, 'OS9: Carabineros participa en 3 de las 4 operaciones (Marlin, Volcán y Centinela 2.0); mayor esfuerzo en Centinela 2.0', null),
      (p, '262066199', false, 'DICDINCAR remite a la DNOS la presentación del Ministerio de Seguridad Pública', null),
      (p, '262105056', false, 'DNOS otorga conformidad; coordinar en forma directa con los estamentos involucrados', '2026-09-08'),
      (p, '262112511', false, 'DICDINCAR dispone al OS9 elaborar la planificación de recursos humanos y logísticos; plazo 14.09.2026 10:00', null),
      (p, '262468487', false, 'OS9: reunión con la DNOS acordada para el martes 15.09.2026 10:00', null),
      (p, '262473856', false, 'DICDINCAR: informar nuevo estado de avance; plazo 21.09.2026 10:00', null),
      (p, '262861869', false, 'OS9 remite Minuta Informativa N°180 y proyecto de orden de servicio de la Operación Centinela 2.0', null),
      (p, '263290870', false, 'DICDINCAR remite a la DNOS minuta y orden de servicio (proforma) para su validación', null),
      (p, '263448325', false, 'DNOS: revisar el proyecto de orden de servicio; plazo 30.09.2026 16:00', null),
      (p, '263500271', false, 'Depto. Planificación Operativa DIOSCAR propone reunión con el Jefe OS9 el 01.10.2026 12:00', null),
      (p, '263512813', false, 'DNOS: informar factibilidad de que el Jefe OS9 concurra a la reunión del 01.10.2026', null),
      (p, '263949355', false, 'Sección Análisis Criminal OS9 remite el proyecto corregido y la planilla "Reporte PARE" (Anexos B y C)', null),
      (p, '263950577', false, 'OS9: para los fines procedentes', null),
      (p, '264318688', false, 'Depto. Planificación Operativa DIOSCAR: orden de servicio con ajustes de forma, en condiciones de ser firmada', null),
      (p, '264319908', false, 'DNOS solicita revisión a la Asesoría Jurídica; plazo 14.10.2026 12:00', null),
      (p, '264459110', false, 'Asesoría Jurídica DIOSCAR solicita prórroga hasta el 16.10.2026', null),
      (p, '264467561', false, 'DNOS autoriza la prórroga; plazo 16.10.2026 10:00', null),
      (p, '264689922', false, 'Asesoría Jurídica remite la orden de servicio proforma corregida (15.10.2026)', null),
      (p, '264733530', false, 'DNOS otorga conformidad', null),
      (p, '264780801', false, 'Asesoría Jurídica: documentación firmada por el Director Nacional, remitida vía estafeta', null),
      (p, '264802122', false, 'DNOS remite la Orden de Servicio DIOSCAR N°67 del 18.10.2026 (Operación Centinela 2.0)', null),
      (p, '264860911', false, 'Depto. Planificación Operativa: derivar a todas las zonas para elaborar plan operativo y ficha Excel; plazo sugerido 21.10.2026 12:00', null),
      (p, '264868627', false, 'DNOS dispone a la Zona elaborar el plan operativo y remitir la ficha; plazo 21.10.2026 12:00', null),
      (p, '264966095', false, 'Zona Arica y Parinacota remite el Plan Operativo de Servicio N°102 (26 al 30.10.2026), con anuencia del Jefe de Zona', null),
      (p, '264992338', false, 'Depto. Planificación Operativa: Plan N°102 de 20.10.2026 acorde al Anexo 2 del Manual (OG N°2.421); sin observaciones de fondo', null),
      (p, '264993685', false, 'DNOS autoriza el Plan N°102; evaluación al Depto. Planificación y Control de Gestión, no más allá de 3 días tras finalizar, con copia a la DNOS', null),
      (p, '264996241', false, 'Zona aprueba el Plan N°102; evaluación a la Zona no más allá de 2 días tras finalizar el servicio', null),
      (p, '265002981', false, 'Prefectura Arica aprueba el Plan N°102; evaluación no más allá de 2 días tras finalizar', null),
      (p, '265079865', false, 'Subprefecto de los Servicios (S) Tcrl. Jorge Pohl remite el Plan N°102: disponer personal y medios; labor diaria a la Subprefectura de los Servicios en formato a convenir; Sección Dron en apresto', null),
      (p, '265083048', false, 'Comisario: conocimiento y estricto cumplimiento del Plan N°102; el Administrador de la Oficina de Operaciones recopila, consolida y remite los resultados. Instrucción vigente', null);
  end if;

  -- ─── ¿Ya tiene el detalle del Plan N°102? ────────────────────
  if exists (select 1 from po_facciones where plan_id = p and nombre like 'Fronterizo · Hitos 1 al 16%') then
    raise notice 'La Operación Centinela 2.0 ya tenía el detalle del Plan N°102; no se hizo nada.';
    return;
  end if;

  -- ─── Datos generales (según el Plan N°102) ───────────────────
  update po_planes set
    numero = '102',
    titulo = 'Operación "Centinela 2.0" — Plan de Acción Operativo sobre Tráfico de Armas (PAO Armas)',
    emisor = 'prefectura',
    emisor_detalle = 'Prefectura Arica N°1 — firma Subprefecto de los Servicios (S) Tcrl. Jorge Andrés Pohl Marín; V°B° Prefecto Crl. Carlos R. Mesa Gallardo. Cumple la Orden de Servicio DIOSCAR N°67 de 18.10.2026; aprobado por la DNOS, la Zona y la Prefectura',
    fecha_emision = '2026-10-20',
    mision = 'Entregar las directrices generales e impartir instrucciones en detalle para la planificación y ejecución de servicios policiales preventivos con motivo de la "Operación Centinela 2.0" (26 al 30.10.2026), con la finalidad de combatir el tráfico ilícito de armas, municiones, partes, piezas, componentes y explosivos, considerando fiscalizaciones en principales rutas y sectores viales de interés, sectores próximos a pasos fronterizos y terminales terrestres, con las unidades y secciones especializadas contempladas en el plan.',
    inicio = '2026-10-26 18:00',
    termino = '2026-10-31 03:00',
    jefe_servicio = 'Comisario de Servicio de la 1ª Com. Arica, 3ª Com. Arica, 4ª Com. Chacalluta (F) y 6ª Com. Chinchorro Norte; Jefe de Tcia. Carreteras Cuya',
    supervisor = 'Prefecto de servicio',
    personal_total_declarado = 45,
    observaciones = 'Puntos sensibles: Terminal Nacional e Internacional, sector Cerro Chuño, sector Miramar, Tenencia Carreteras Arica y otros puntos de interés según información de la SPF. Oficial encargado del aseguramiento y levantamiento de evidencias: Tte. Jorge Cares Elgueta (Labocar Arica), con apoyo del oficial de servicio de la Sección OS9. Mantener los servicios preventivos en la población sin afectar la oferta real diaria. Cada comisario designa personal idóneo, de preferencia de la oficina de operaciones, para cuentas e informes; labor diaria a la Subprefectura de los Servicios (formato a convenir); las secciones especializadas informan su labor a la unidad territorial donde actúen; la Sección Dron se mantiene en apresto. Reunión de término en el cuartel de cada unidad. Contexto: operación simultánea con "Marlin", "Dron" y "Volcán"; en Centinela 2.0 participan Carabineros, PDI, Aduanas y Gendarmería. Reporte institucional DIOSCAR en planilla "Reporte PARE" (Anexos B y C).'
  where id = p;

  -- Reemplaza el detalle provisorio de la versión anterior del script
  delete from po_facciones       where plan_id = p;
  delete from po_servicios       where plan_id = p;
  delete from po_plazos          where plan_id = p;
  delete from po_contradicciones where plan_id = p;

  -- ═══ Bloque A · lunes 26, miércoles 28 y viernes 30.10: presentación 17:30, 18:00 a 00:00 ═══
  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Bloque A · 1ª Com. Arica — Miramar y Altos del Mar',
          'Rafael Sotomayor / San Ignacio de Loyola (Pobl. Miramar y Altos del Mar); SIP: fiscalizaciones en Miramar y Altos del Mar', u_1c, 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, fz, nota) values (p, f, u_1c, 1, 3, 1, 'Anexo: 1 PNS (oficial)');
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values (p, f, u_1s, 2, 1);
  foreach d in array array['2026-10-26','2026-10-28','2026-10-30']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '18:00', d + 1 + time '00:00', d + time '17:30', 'Cuartel de cada unidad');
  end loop;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Bloque A · 3ª Com. Arica + OS7 — Terminal Nacional e Internacional',
          'Terminal Nacional e Internacional; SIP: inmediaciones del terminal; OS7: sectores aledaños al terminal', u_3c, 2)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, fz, nota) values (p, f, u_3c, 1, 3, 1, 'Anexo: 1 PNS (oficial)');
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values (p, f, u_3s, 2, 1), (p, f, u_os7, 3, 1);
  foreach d in array array['2026-10-26','2026-10-28','2026-10-30']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '18:00', d + 1 + time '00:00', d + time '17:30', 'Cuartel de cada unidad');
  end loop;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Bloque A · 6ª Com. Chinchorro Norte + OS9 — Sector Cerro Chuño',
          'Sector Cerro Chuño (Pje. 7, Capitán Ávalos, Morrillo); SIP y OS9: fiscalizaciones en el sector', u_6c, 3)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, fz, nota) values (p, f, u_6c, 1, 3, 1, 'Anexo: 1 PNS (oficial)');
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values (p, f, u_6s, 2, 1), (p, f, u_os9, 3, 1);
  foreach d in array array['2026-10-26','2026-10-28','2026-10-30']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '18:00', d + 1 + time '00:00', d + time '17:30', 'Cuartel de cada unidad');
  end loop;

  -- ═══ Tcia. Carreteras Arica · todos los días (A: 18:00–00:00 · B: 16:00–22:00) ═══
  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Tcia. Carreteras Arica — Punto de control exterior', 'Punto de control exterior de la Tenencia Carreteras Arica', u_car, 4)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni) values (p, f, u_car, 2);
  foreach d in array array['2026-10-26','2026-10-28','2026-10-30']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '18:00', d + 1 + time '00:00', d + time '17:30', 'Cuartel de la unidad');
  end loop;
  foreach d in array array['2026-10-27','2026-10-29']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '16:00', d + time '22:00', d + time '15:30', 'Cuartel de la unidad');
  end loop;

  -- ═══ Bloque B · martes 27 y jueves 29.10: presentación 15:30, 16:00 a 22:00 ═══
  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Bloque B · 3ª Com. Arica + OS9 — Terminal Nacional e Internacional',
          'Terminal Nacional e Internacional; SIP: inmediaciones del terminal; OS9: sectores aledaños al terminal', u_3c, 5)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p, f, u_3c, 3, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap, nota)
  values (p, f, u_3s, 3, 1, 'Anexo días 27 y 29: 3 PNI; el Resumen General indica 2 PNI para la SIP 3ª (ver contradicción)');
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values (p, f, u_os9, 3, 1);
  foreach d in array array['2026-10-27','2026-10-29']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '16:00', d + time '22:00', d + time '15:30', 'Cuartel de cada unidad');
  end loop;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Bloque B · 6ª Com. Chinchorro Norte + OS7 — Sector Cerro Chuño',
          'Sector Cerro Chuño (Pje. 7, Capitán Ávalos, Morrillo); OS7: fiscalización en el sector', u_6c, 6)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p, f, u_6c, 3, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values (p, f, u_os7, 3, 1);
  foreach d in array array['2026-10-27','2026-10-29']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '16:00', d + time '22:00', d + time '15:30', 'Cuartel de cada unidad');
  end loop;

  -- ═══ Sector fronterizo · 26 al 30.10: presentación 21:30, 22:00 a 03:00 ═══
  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Fronterizo · Hitos 1 al 16', 'Pasos no habilitados Hitos 1 al 16', u_com, 7) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p, f, u_com, 3, 1);
  for i in 0..4 loop
    d := date '2026-10-26' + i;
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '22:00', d + 1 + time '03:00', d + time '21:30', 'Cuartel de la unidad');
  end loop;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Fronterizo · Aguas Calientes (R. Tacora)', 'Pasos no habilitados sector "Aguas Calientes"', u_tac, 8) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p, f, u_tac, 3, 1);
  for i in 0..4 loop
    d := date '2026-10-26' + i;
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '22:00', d + 1 + time '03:00', d + time '21:30', 'Cuartel de la unidad');
  end loop;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Fronterizo · Aguas Calientes (R. Alcérreca)', 'Pasos no habilitados sector "Aguas Calientes"', u_alc, 9) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p, f, u_alc, 3, 1);
  for i in 0..4 loop
    d := date '2026-10-26' + i;
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '22:00', d + 1 + time '03:00', d + time '21:30', 'Cuartel de la unidad');
  end loop;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Fronterizo · Ruta 11-CH km 159 (R. Chucuyo)', 'Ruta 11-CH, km 159', u_cuy, 10) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p, f, u_cuy, 3, 1);
  for i in 0..4 loop
    d := date '2026-10-26' + i;
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '22:00', d + 1 + time '03:00', d + time '21:30', 'Cuartel de la unidad');
  end loop;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p, 'Fronterizo · Laguna Blanca Hito 69 (Tcia. Visviri)', 'Laguna Blanca, Hito 69', u_vis, 11) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, fz, nota) values (p, f, u_vis, 1, 3, 1, 'Anexo: 1 PNS (oficial)');
  for i in 0..4 loop
    d := date '2026-10-26' + i;
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p, f, d + time '22:00', d + 1 + time '03:00', d + time '21:30', 'Cuartel de la unidad');
  end loop;

  -- ═══ Recursos sin facción horaria en el plan ═══
  insert into po_facciones (plan_id, nombre, observaciones, orden)
  values (p, 'Plana Mayor — supervisión', 'Refuerzo de Plana Mayor del Resumen General; el plan no le asigna facción ni horario', 12) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, tcrl, pni, fz) values (p, f, u_pm, 1, 1, 1);

  insert into po_facciones (plan_id, nombre, observaciones, orden)
  values (p, 'Sección Dron — apresto', 'En apresto ante cualquier requerimiento de los jefes de servicio (DOE NCU 265079865)', 13) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, nota) values (p, f, u_dron, 3, '1 dron');

  -- ═══ Plazos ═══
  insert into po_plazos (plan_id, tipo, descripcion, destinatario, formato) values
    (p, 'labor', 'Labor realizada en forma diaria, del 26 al 30.10.2026 (hora no especificada). Recopila, consolida y remite el Administrador de la Oficina de Operaciones (personal idóneo designado por el Comisario)',
     'Subprefectura de los Servicios, Prefectura Arica', 'Formato a convenir');
  insert into po_plazos (plan_id, tipo, descripcion, vence, al_termino_servicio, destinatario, formato) values
    (p, 'evaluacion', 'Evaluación de los servicios desplegados "no más allá de 2 días" tras finalizar (último servicio termina el 31.10.2026 03:00), según Zona y Prefectura — NCU 264996241 / 265002981. Ver contradicción con el plazo de 3 días del Plan N°102',
     '2026-11-02 03:00', true, 'Zona Carabs. Arica y Parinacota (vía Prefectura)', 'Modelo del Manual para la Planificación Operativa e instrucciones de la Prefectura');

  -- ═══ Contradicciones detectadas en el Plan N°102 ═══
  insert into po_contradicciones (plan_id, campo, valor_a, fuente_a, valor_b, fuente_b) values
    (p, 'Personal 4ª Com. Chacalluta (F)', 'Total 15', 'Resumen General (columna TOTAL)',
        '1 Ofl. + 15 PNI = 16 (coincide con el anexo del sector fronterizo: 1 PNS + 15 PNI)', 'Resumen General (columnas por grado) y anexo'),
    (p, 'Total refuerzos territoriales', 'Total 35', 'Resumen General (fila TOTAL GRAL.)',
        '1 Tcrl + 4 Ofl. + 31 PNI = 36 (el total general de 45 sí suma 1 + 4 + 40)', 'Resumen General (columnas por grado)'),
    (p, 'Medios 4ª Com. Chacalluta (F)', '5 AP', 'Resumen General', '5 FZ (una por facción fronteriza) y 0 AP', 'Anexo sector fronterizo'),
    (p, 'Personal SIP 3ª Com. Arica', '2 PNI', 'Resumen General y anexo días 26, 28 y 30', '3 PNI', 'Anexo días 27 y 29'),
    (p, 'Plazo de la evaluación', 'No mayor de 3 días después de finalizados los servicios', 'Plan N°102, III Fase (y DNOS, NCU 264993685)',
        'No más allá de 2 días', 'Zona (NCU 264996241) y Prefectura (NCU 265002981)');

  raise notice 'Operación Centinela 2.0: detalle del Plan N°102 cargado (13 facciones, 45 funcionarios).';
end $$;

commit;
