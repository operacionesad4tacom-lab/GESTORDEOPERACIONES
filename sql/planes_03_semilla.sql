-- ═══════════════════════════════════════════════════════════════
-- SIGO — Control de Planes Operativos
-- 03 · Semilla de prueba (casos reales P1–P8, ya confirmados)
-- Ejecutar después de 02_seguridad.sql. Es idempotente: si ya se cargó, no hace nada.
-- Campos que los documentos no traen quedan en NULL ("No especificado").
-- ═══════════════════════════════════════════════════════════════

begin;
set local time zone 'America/Santiago';

do $$
declare
  -- unidades
  u_com uuid; u_sip uuid; u_chu uuid; u_vis uuid; u_cuy uuid; u_tac uuid;
  u_gua uuid; u_chi uuid; u_car uuid; u_os7 uuid; u_os9 uuid;
  -- planes
  p1 uuid; p2 uuid; p3 uuid; p4 uuid; p5 uuid; p6 uuid; p7 uuid; p8 uuid;
  -- etapas y facciones
  e1 uuid; e2 uuid; f uuid; f2 uuid;
  d date;
  i int;
begin
  if exists (select 1 from po_ncu where ncu = '264753566') then
    raise notice 'La semilla ya estaba cargada; no se hizo nada.';
    return;
  end if;

  select id into u_com from po_unidades where sigla = '4ta Com.';
  select id into u_sip from po_unidades where sigla = 'SIP 4ta Com.';
  select id into u_chu from po_unidades where sigla = 'Tcia. Chungará';
  select id into u_vis from po_unidades where sigla = 'Tcia. Visviri';
  select id into u_cuy from po_unidades where sigla = 'Retén Chucuyo';
  select id into u_tac from po_unidades where sigla = 'Retén Tacora';
  select id into u_gua from po_unidades where sigla = 'Retén Guallatire';
  select id into u_chi from po_unidades where sigla = 'Retén Chilcaya';
  select id into u_car from po_unidades where sigla = 'Tcia. Carretera';
  select id into u_os7 from po_unidades where sigla = 'OS7';
  select id into u_os9 from po_unidades where sigla = 'OS9';

  -- ═══ P1 · Plan N°03 Subprefectura Fronteriza ═══════════════════
  insert into po_planes (tipo, numero, titulo, emisor, fecha_emision, inicio, termino,
                         jefe_servicio, supervisor, revision, confirmado_en)
  values ('plan_operativo', '03',
          'Servicios extraordinarios Fortalecimiento CF Chungará, inmediaciones y ruta de conexión con Arica',
          'subprefectura_fronteriza', '2026-10-02',
          '2026-10-05 14:00', '2026-10-20 20:00',
          'Tte. Ignacio Acuña Ayala', 'Tcrl. Raúl Arismendi Atencio', 'confirmado', now())
  returning id into p1;

  insert into po_ncu (plan_id, ncu) values (p1, '264733174'), (p1, '264729932'), (p1, '263854679');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p1, 'PC N°1', 'CF Chungará', u_chu, 1) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pns, pni, ap) values (p1, f, u_chu, 1, 2, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, can, ap) values (p1, f, u_os7, 3, 1, 1);

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p1, 'PC N°2', 'Ruta 11-CH km 159 (Retén Chucuyo)', u_cuy, 2) returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p1, f2, u_cuy, 2, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap, nota)
  values (p1, f2, u_sip, 4, 1, 'Cantidad según anexo; el resumen indica 2 PNI (ver contradicción)');

  foreach d in array array['2026-10-05','2026-10-06','2026-10-19','2026-10-20']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion) values
      (p1, f,  d + time '14:00', d + time '20:00', d + time '13:30', 'Tcia. Chungará (F)'),
      (p1, f2, d + time '14:00', d + time '20:00', d + time '13:30', 'Retén Chucuyo (F)');
  end loop;

  insert into po_plazos (plan_id, tipo, descripcion, vence, estado, cumplido_en) values
    (p1, 'labor', 'Labor 1er bloque (05-06.10.2026)', '2026-10-07 08:00', 'cumplido', '2026-10-07 08:00');
  insert into po_plazos (plan_id, tipo, descripcion, vence, al_termino_servicio, destinatario, formato) values
    (p1, 'labor', 'Labor 2º bloque: inmediatamente finalizado el servicio del 20.10.2026',
     '2026-10-20 20:00', true, 'Consolidada por el Jefe Tcia. Chungará (F), incluyendo OS7',
     'Con evaluación según Manual de Planificación Operativa');

  insert into po_contradicciones (plan_id, campo, valor_a, fuente_a, valor_b, fuente_b) values
    (p1, 'PC N°2 · personal SIP 4ta Com.', '2 PNI', 'Resumen del plan', '4 PNI, 1 AP', 'Anexo del plan');

  -- ═══ P2 · Plan Operativo Fortalecimiento CF Chungará (permanente) ═
  insert into po_planes (tipo, titulo, emisor, emisor_detalle, hasta_nueva_orden, recurrencia,
                         observaciones, revision, confirmado_en)
  values ('plan_operativo', 'Plan Operativo Fortalecimiento CF Chungará', 'seremi',
          'Seremi de Seguridad Pública / Zona', true,
          'PC1 y PC2: lunes y martes, 2 semanas al mes (semanas no especificadas). PC3: 1 vez por semana.',
          'Medida de mediano plazo: traslado del camión escáner desde CF Chacalluta.',
          'confirmado', now())
  returning id into p2;

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, observaciones, orden)
  values (p2, 'PC1 · Refuerzo CF Chungará', 'CF Chungará', u_chu,
          'Lunes y martes, 2 semanas al mes, con binomios caninos OS7', 1) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota)
  values (p2, f, u_os7, 'Binomios caninos (cantidad no especificada)');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, observaciones, orden)
  values (p2, 'PC2 · Controles integrados Retén Chucuyo', 'Ruta 11-CH km 159', u_cuy,
          'Lunes y martes, 2 semanas al mes, jornada PM', 2);

  insert into po_facciones (plan_id, nombre, lugar, observaciones, orden)
  values (p2, 'PC3 · Controles integrados en Arica', null,
          'Lugar por definir: Truck Center Lluta km 1, antepuerto EPA, Ruta 11-CH km 5-8 o Poconchile. 1 vez por semana.', 3);

  insert into po_plazos (plan_id, tipo, descripcion) values
    (p2, 'informe_semanal', 'Informe semanal con indicadores (día y hora no especificados)');

  insert into po_indicadores (plan_id, nombre, tipo, numerador, denominador, orden) values
    (p2, '% cumplimiento',              'porcentaje', 'Operativos realizados', 'Operativos comprometidos', 1),
    (p2, '% participación institucional','porcentaje', 'Instituciones participantes', 'Instituciones convocadas', 2),
    (p2, 'Vehículos fiscalizados',      'numero', null, null, 3),
    (p2, 'Vehículos devueltos a Bolivia','numero', null, null, 4),
    (p2, 'Resultados',                  'numero', null, null, 5);

  -- ═══ P3 · Plan Abreviado N°02 – Operativo Binacional con SUNAT ════
  insert into po_planes (tipo, numero, titulo, emisor, inicio, termino, revision, confirmado_en)
  values ('plan_abreviado', '02', 'Operativo Binacional Perú-Chile con SUNAT', 'comisaria',
          '2026-10-19 00:00', '2026-10-31 23:59', 'confirmado', now())
  returning id into p3;

  insert into po_ncu (plan_id, ncu, resumen) values (p3, '264759190', 'Ref. DOE');

  insert into po_etapas (plan_id, nombre, inicio, termino, lugar, orden)
  values (p3, 'Etapa 1', '2026-10-19 00:00', '2026-10-30 23:59', 'CF Chacalluta y CF Visviri', 1)
  returning id into e1;
  insert into po_etapas (plan_id, nombre, inicio, termino, lugar, tactica, orden)
  values (p3, 'Etapa 2 · Ceremonia de cierre', '2026-10-31 00:00', '2026-10-31 23:59', 'Hito Tripartito',
          'Jefe: Subcomisario de los Servicios. Hora por confirmar.', 2)
  returning id into e2;

  insert into po_facciones (plan_id, etapa_id, nombre, lugar, apoyo_instituciones, orden)
  values (p3, e1, 'Etapa 1 · CF Chacalluta y CF Visviri', 'CF Chacalluta y CF Visviri', '{SUNAT}', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values
    (p3, f, u_com, 2, 1), (p3, f, u_vis, 2, 1);
  insert into po_servicios (plan_id, faccion_id, etapa_id, inicio, termino, hora_por_confirmar, observaciones)
  values (p3, f, e1, '2026-10-19 00:00', '2026-10-30 23:59', true, 'Horario conforme coordinación internacional');

  insert into po_facciones (plan_id, etapa_id, nombre, lugar, jefe_faccion, apoyo_instituciones, orden)
  values (p3, e2, 'Etapa 2 · Ceremonia Hito Tripartito', 'Hito Tripartito', 'Subcomisario de los Servicios', '{SUNAT}', 2)
  returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, cap, pni, ap) values (p3, f2, u_com, 1, 1, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, ap) values (p3, f2, u_vis, 1, 5, 1);
  insert into po_servicios (plan_id, faccion_id, etapa_id, inicio, termino, hora_por_confirmar)
  values (p3, f2, e2, '2026-10-31 00:00', '2026-10-31 23:59', true);

  insert into po_plazos (plan_id, tipo, vence) values (p3, 'evaluacion', '2026-11-02 15:00');

  -- ═══ P4 · Refuerzo Facción Centinela 3 ═════════════════════════
  insert into po_planes (tipo, titulo, inicio, termino, revision, confirmado_en)
  values ('orden_doe', 'Refuerzo Facción Centinela 3', '2026-10-17 06:00', '2026-10-24 06:00', 'confirmado', now())
  returning id into p4;

  insert into po_ncu (plan_id, ncu) values (p4, '264744370');

  insert into po_facciones (plan_id, nombre, unidad_cargo_id, apoyo_instituciones, apoyo_detalle, orden)
  values (p4, 'Facción Centinela 3', u_com, '{Ejército}',
          'Días 21, 22 y 23.10: el 2º turno suma personal del Ejército (Fuerza de Tarea Arica). Contacto: Cap. Álvaro García.', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota)
  values (p4, f, u_com, 'Dotación por turno no especificada');

  for i in 0..6 loop
    d := date '2026-10-17' + i;
    insert into po_servicios (plan_id, faccion_id, turno, inicio, termino, institucion) values
      (p4, f, '1er turno', d + time '06:00', d + time '14:00', 'Carabineros (4ta Com.)'),
      (p4, f, '2º turno',
         d + case when extract(dow from d) = 0 then time '14:00' else time '15:00' end,
         d + time '21:00',
         case when d between date '2026-10-21' and date '2026-10-23'
              then 'Carabineros (4ta Com.) + Ejército (Fuerza de Tarea Arica)'
              else 'Carabineros (4ta Com.)' end),
      (p4, f, '3er turno', d + time '22:00', d + 1 + time '06:00', 'Carabineros (4ta Com.)');
  end loop;

  -- ═══ P5 · Plan Barrera Norte N°05 Prefectura Arica ═════════════
  insert into po_planes (tipo, numero, titulo, emisor, inicio, termino, jefe_servicio, supervisor,
                         personal_total_declarado, revision, confirmado_en)
  values ('plan_operativo', '05', 'Plan Barrera Norte', 'prefectura',
          '2026-10-22 00:00', '2026-10-23 23:59', 'Tte. Jorge Reyes Olivares (OS7)',
          '1ª línea: Tcrl. Raúl Arismendi · 2ª línea: Tcrl. Jorge Pohl Marín',
          41, 'confirmado', now())
  returning id into p5;

  insert into po_ncu (plan_id, ncu) values (p5, '264753566');

  insert into po_facciones (plan_id, nombre, lugar, orden)
  values (p5, 'Despliegue Barrera Norte',
          'Ruta 11-CH km 1-192, km 126; A-31 km 15-17; A-31/A-201; A-319/A-95; pasos no habilitados Laguna Blanca, Hito XVII y Guacollo; Rutas A-191 y A-143', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, cap, tte, pni, fz, ap) values
    (p5, f, u_com, 1,    null, 2, null, 1),
    (p5, f, u_sip, null, null, 2, null, 1),
    (p5, f, u_vis, null, null, 3, null, 1),
    (p5, f, u_chu, null, 1,    2, null, 1),
    (p5, f, u_tac, null, null, 3, null, 1),
    (p5, f, u_cuy, null, null, 3, 1,    null),
    (p5, f, u_gua, null, null, 3, null, 1),
    (p5, f, u_chi, null, null, 3, null, 1);
  insert into po_servicios (plan_id, faccion_id, inicio, termino)
  values (p5, f, '2026-10-22 00:00', '2026-10-23 23:59');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, jefe_faccion, orden)
  values (p5, 'Refuerzo OS7 a Tcia. Carretera', 'Tenencia Carretera', u_os7, 'Tte. Jorge Reyes Olivares (OS7)', 2)
  returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota)
  values (p5, f2, u_os7, 'Dotación no especificada');
  foreach d in array array['2026-10-21','2026-10-22','2026-10-23']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino)
    values (p5, f2, d + time '15:00', d + time '21:00');
  end loop;

  insert into po_plazos (plan_id, tipo, vence, formato)
  values (p5, 'labor', '2026-10-24 10:00', 'Excel adjunto al plan');

  insert into po_contradicciones (plan_id, campo, valor_a, fuente_a, valor_b, fuente_b) values
    (p5, 'Fechas del servicio', '00:00 del 22.10 a 23:59 del 23.10.2026', 'Plan', 'Días 21 y 23', 'DOE que remite el plan');

  -- ═══ P6 · Emergencia preventiva "Sistema Frontal" ══════════════
  insert into po_planes (tipo, titulo, inicio, termino, mision, observaciones, revision, confirmado_en)
  values ('emergencia', 'Emergencia preventiva "Sistema Frontal"',
          '2026-10-18 00:00', '2026-10-23 23:59',
          'Revisar grupos electrógenos y tenidas impermeables; difusión al personal con constancia en libros.',
          'Decreto Exento N°1.407. Bajo Plan DIOSCAR N°11 (20.04.2026, vigente hasta nueva orden).',
          'confirmado', now())
  returning id into p6;

  insert into po_ncu (plan_id, ncu) values (p6, '264854195');
  insert into po_servicios (plan_id, inicio, termino, observaciones)
  values (p6, '2026-10-18 00:00', '2026-10-23 23:59', 'Emergencia sin facciones definidas');

  -- ═══ P7 · Mesa de coordinación Plan Regional contra el Crimen Organizado ═
  insert into po_planes (tipo, titulo, inicio, termino, revision, confirmado_en)
  values ('mesa_coordinacion', 'Mesa de coordinación Plan Regional contra el Crimen Organizado · octubre 2026',
          '2026-10-20 02:00', '2026-10-28 23:59', 'confirmado', now())
  returning id into p7;

  insert into po_ncu (plan_id, ncu) values (p7, '264647954');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p7, 'Fiscalizaciones CF Chacalluta', 'CF Chacalluta', u_com, 1) returning id into f;
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-20 22:00', '2026-10-21 00:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_detalle, orden)
  values (p7, 'Operativo Ruta A-235', 'Ruta A-235, Guallatire', 'OS7 y OS9', 2) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id) values (p7, f, u_os7), (p7, f, u_os9);
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-21 12:00', '2026-10-21 16:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_instituciones, apoyo_detalle, orden)
  values (p7, 'Controles Ruta A-143', 'Ruta A-143', '{PDI}', 'PDI y SEBV', 3) returning id into f;
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-20 02:00', '2026-10-20 06:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_instituciones, orden)
  values (p7, 'Operativo Quebrada Encantada', 'Quebrada Encantada', '{SAG,SII}', 4) returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id) values (p7, f, u_os7);
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-26 06:00', '2026-10-26 10:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_instituciones, orden)
  values (p7, 'Capacitación lavado de activos', null, '{PDI}', 5) returning id into f;
  insert into po_servicios (plan_id, faccion_id, inicio, termino, hora_por_confirmar, observaciones)
  values (p7, f, '2026-10-28 00:00', '2026-10-28 23:59', true, 'Lugar y hora por definir');

  -- ═══ P8 · Campeonato Internacional de Ciclismo Arica-Tacna ═════
  insert into po_planes (tipo, titulo, inicio, termino, observaciones, revision, confirmado_en)
  values ('evento_preparacion', 'Campeonato Internacional de Ciclismo de Ruta Arica-Tacna',
          '2026-12-11 00:00', '2026-12-13 23:59',
          'Pendientes: circuito definitivo, protocolos migratorios y aduaneros, despliegue policial. Competencia con cruce de frontera.',
          'confirmado', now())
  returning id into p8;

  insert into po_ncu (plan_id, ncu) values (p8, '264856380');
  insert into po_etapas (plan_id, nombre, inicio, termino, orden) values
    (p8, 'Lanzamiento', '2026-12-11 00:00', '2026-12-11 23:59', 1),
    (p8, 'Competencia (con cruce de frontera)', '2026-12-12 00:00', '2026-12-13 23:59', 2);

  raise notice 'Semilla cargada: 8 planes.';
end $$;

commit;
