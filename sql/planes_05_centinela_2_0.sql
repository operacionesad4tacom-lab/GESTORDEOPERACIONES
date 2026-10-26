-- ═══════════════════════════════════════════════════════════════
-- SIGO — Control de Planes Operativos
-- 05 · Operación "Centinela 2.0" — PAO Tráfico de Armas (Plan Operativo N°102, DOE NCU 265083048)
-- Ejecutar en Supabase → SQL Editor. Es idempotente: si el NCU ya existe, no hace nada.
-- Queda en "Por revisar": confirmarlo desde su ficha para activarlo.
--
-- El texto del Plan N°102 (facciones, horarios, personal y medios) no viene en la traza DOE:
-- esos datos quedan "No especificado" hasta cargarlos desde el plan.
-- ═══════════════════════════════════════════════════════════════

begin;
set local time zone 'America/Santiago';

do $$
declare
  u_com uuid;
  p uuid; f uuid;
begin
  if exists (select 1 from po_ncu where ncu = '265083048') then
    raise notice 'La Operación Centinela 2.0 ya estaba cargada; no se hizo nada.';
    return;
  end if;

  select id into u_com from po_unidades where sigla = '4ta Com.';

  insert into po_planes (tipo, numero, titulo, emisor, emisor_detalle, fecha_emision, mision, inicio, termino,
                         observaciones, revision)
  values ('plan_operativo', '102', 'Operación "Centinela 2.0" — Plan de Acción Operativo sobre Tráfico de Armas (PAO Armas)',
          'prefectura',
          'Prefectura Arica N°1, en cumplimiento de la Orden de Servicio DIOSCAR N°67 de 18.10.2026. Aprobado por la DNOS, la Zona Arica y Parinacota y la Prefectura Arica',
          '2026-10-20',
          'Implementar los servicios policiales de la Operación "Centinela 2.0" (control terrestre, coordinada por Chile) del Plan de Acción Operativo sobre Tráfico de Armas, a nivel nacional entre el 26 y el 30.10.2026: control en rutas y pasos fronterizos, fiscalizaciones relacionadas con armas de fuego, controles preventivos y procedimientos policiales afines, priorizando sectores según perfil dinámico y realidad territorial.',
          '2026-10-26 00:00', '2026-10-30 23:59',
          'Origen: solicitud del Ministerio de Seguridad Pública (División de Crimen Organizado, Terrorismo y Seguridad Fronteriza) vía CICPOL. Operación simultánea con "Marlin" (rutas marítimas), "Dron" (carga aérea) y "Volcán" (paquetería y mensajería); en Centinela 2.0 participan Carabineros, PDI, Servicio Nacional de Aduanas y Gendarmería. Según la Subprefectura de los Servicios: las unidades disponen personal y medios conforme a la planificación; las secciones especializadas informan su labor a la unidad territorial donde actúen, para que esta la informe; la Sección Dron se mantiene en apresto ante requerimientos de los jefes de servicio. El Comisario dispone que el Administrador de la Oficina de Operaciones recopile, consolide y remita oportunamente los resultados de la unidad y sus destacamentos. Reporte institucional DIOSCAR en planilla "Reporte PARE" (Anexo B informe diario operacional, Anexo C informe detallado operacional). El texto del Plan N°102 no viene en la traza: facciones, horarios y recursos quedan por cargar.',
          'por_revisar')
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

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_instituciones, apoyo_detalle, observaciones, orden)
  values (p, '4ta. Com. Chacalluta (F) y destacamentos involucrados', null, u_com, '{PDI,Aduanas,Gendarmería}',
          'Instituciones participantes en la Operación Centinela 2.0 a nivel nacional',
          'Facciones, lugares y horarios según Plan N°102 (no adjunto a la traza DOE)', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota)
  values (p, f, u_com, 'Personal y medios según Plan N°102 (no especificados en la traza DOE)');
  insert into po_servicios (plan_id, faccion_id, inicio, termino, hora_por_confirmar, observaciones)
  values (p, f, '2026-10-26 00:00', '2026-10-30 23:59', true, 'Horarios según Plan N°102');

  insert into po_plazos (plan_id, tipo, descripcion, destinatario, formato) values
    (p, 'labor', 'Labor realizada en forma diaria, del 26 al 30.10.2026 (hora no especificada). Recopila, consolida y remite el Administrador de la Oficina de Operaciones',
     'Subprefectura de los Servicios, Prefectura Arica', 'Formato a convenir');
  insert into po_plazos (plan_id, tipo, descripcion, vence, al_termino_servicio, destinatario, formato) values
    (p, 'evaluacion', 'Evaluación del Plan N°102 "no más allá de 2 días" tras finalizar el servicio (30.10.2026), según Zona y Prefectura — NCU 264996241 / 265002981',
     '2026-11-01 23:59', true, 'Zona Carabs. Arica y Parinacota', 'Según Manual de Planificación Operativa');

  raise notice 'Operación Centinela 2.0 cargada en "Por revisar".';
end $$;

commit;
