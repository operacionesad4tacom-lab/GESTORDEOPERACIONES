-- ═══════════════════════════════════════════════════════════════
-- SIGO — Control de Planes Operativos
-- 03 · Carga de planes vigentes al 19.10.2026
-- Fuente: documentos de la carpeta "PLANES DE SERVICIOS" (planes y trazas DOE).
-- Ejecutar después de 02_seguridad.sql. Es idempotente: si ya se cargó, no hace nada.
--
-- Reglas aplicadas:
--  · Solo se carga lo que los documentos dicen explícitamente; lo demás queda NULL ("No especificado").
--  · Las diferencias entre documentos se registran como contradicciones, no se resuelven.
--  · En cada traza DOE, la última adición es la instrucción vigente; las anteriores quedan como historial.
--  · No se almacenan RUT (marcas de agua "Abierto por RUT ...") ni nóminas de personal.
--  · P1–P8 quedan confirmados; el Plan DIOSCAR N°11 (marco nacional) queda en "Por revisar".
-- ═══════════════════════════════════════════════════════════════

begin;
set local time zone 'America/Santiago';

do $$
declare
  -- unidades
  u_com uuid; u_sip uuid; u_chu uuid; u_vis uuid; u_cuy uuid; u_tac uuid; u_gua uuid; u_chi uuid;
  u_car uuid; u_os7 uuid; u_os9 uuid; u_put uuid; u_chp uuid; u_poc uuid; u_azp uuid;
  -- planes
  p1 uuid; p2 uuid; p3 uuid; p4 uuid; p5 uuid; p6 uuid; p7 uuid; p8 uuid; p9 uuid;
  -- etapas y facciones
  e1 uuid; e2 uuid; f uuid; f2 uuid; f3 uuid;
  d date;
  i int;
begin
  if exists (select 1 from po_ncu where ncu = '264753566') then
    raise notice 'La carga ya estaba realizada; no se hizo nada.';
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
  select id into u_put from po_unidades where sigla = '2da Com. Putre';
  select id into u_chp from po_unidades where sigla = 'Retén Chapiquiña';
  select id into u_poc from po_unidades where sigla = 'Retén Poconchile';
  select id into u_azp from po_unidades where sigla = 'Retén Azapa';

  -- ═══ P1 · Plan N°03 Subprefectura Fronteriza ══════════════════
  -- Fuente: PLAN NRO. 03.pdf + traza DOE NCU 264733174 (compartida con P2)
  insert into po_planes (tipo, numero, titulo, emisor, emisor_detalle, fecha_emision, mision, inicio, termino,
                         jefe_servicio, supervisor, observaciones, revision, confirmado_en)
  values ('plan_operativo', '03',
          'Servicios extraordinarios Fortalecimiento Complejo Fronterizo Chungará, inmediaciones y ruta de conexión con la comuna de Arica',
          'subprefectura_fronteriza', 'Subprefectura Fronteriza, Prefectura Arica N°1. V°B° Prefecto Crl. Carlos R. Mesa Gallardo',
          '2026-10-02',
          'Ejecutar servicios policiales extraordinarios de Orden y Seguridad con recursos de la 4ta. Com. Chacalluta (F), sus destacamentos fronterizos y la Sección Antidrogas O.S.7 Arica, para fortalecer la fiscalización y control en el CF Chungará, Ruta 11-CH y sectores de interés, orientados a la prevención, detección y control de delitos transnacionales (tráfico de drogas, contrabando). Se refuerza la presencia en el CF Chungará y se efectúan controles focalizados en la Ruta 11-CH, sector Retén Chucuyo (F), km 159.',
          '2026-10-05 14:00', '2026-10-20 20:00',
          'Tte. Ignacio Acuña Ayala, Jefe Tcia. Chungará (F) o quien lo subrogue',
          'Tcrl. Raúl Arismendi Atencio, Subprefecto Fronterizo',
          'Operacionaliza los PC N°1 y N°2 del Plan Operativo de Fortalecimiento del CF Chungará (Zona / Seremi). Magnitud: no determinada. Cuenta Jefe del Servicio 13:30 hrs. Los días y lugares no pueden ser modificados. Consolidación de resultados: controles, vehículos fiscalizados, vehículos devueltos a Bolivia, procedimientos, infracciones, detenidos, drogas y mercancías incautadas. Evaluación a la Subprefectura Fronteriza según Manual de Planificación Operativa.',
          'confirmado', now())
  returning id into p1;

  insert into po_ncu (plan_id, ncu, es_origen, resumen) values
    (p1, '263826547', true,  'Subprefecto Fronterizo remite Plan Operativo N°03 al Prefecto para su validación'),
    (p1, '263829247', false, 'Prefectura remite el Plan N°03 con la rúbrica del Prefecto'),
    (p1, '263840570', false, 'Subprefecto: conocimiento y cumplimiento; acuse de recibo con la palabra "PLAN OPERATIVO N.° 03", plazo hoy 12:00'),
    (p1, '263842066', false, 'Comisario acusa recibo: "PLAN OPERATIVO N.° 03"'),
    (p1, '263854679', false, 'Subprefecto: Jefe Tcia. Chungará consolida y remite labor de lunes y martes (CF Chungará + Retén Chucuyo + OS7). Plazo 07.10.2026 08:00, impostergable'),
    (p1, '264729932', false, 'Subprefecto: servicio dispuesto para el 19 y 20.10.2026; consolidar labor y evaluación según Manual; acuse de recibo plazo 17.10.2026 10:00'),
    (p1, '264733174', false, 'Comisario (16.10.2026 16:50) al Jefe Tcia. Chungará (S): remitir labor y evaluación inmediatamente una vez finalizado el servicio. Instrucción vigente');
  update po_ncu set fecha = '2026-10-16' where plan_id = p1 and ncu = '264733174';

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_detalle, orden)
  values (p1, 'PC N°1', 'Complejo Fronterizo Chungará', u_chu,
          'OS7: un Guía de Perros Policiales con ejemplar canino detector de drogas permanece en el CF Chungará', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, ap, nota)
  values (p1, f, u_chu, 1, 2, 1, 'Resumen general: 1 Tte; Anexo N°1: 1 P.N.S. (oficial)');
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, can, ap) values (p1, f, u_os7, 3, 1, 1);

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, orden)
  values (p1, 'PC N°2', 'Ruta 11-CH, altura km 159 (sector Retén Chucuyo)', u_cuy, 2)
  returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p1, f2, u_cuy, 2, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap, nota)
  values (p1, f2, u_sip, 4, 1, 'Cantidad según Anexo N°1; el Resumen General indica 2 PNI (ver contradicción)');

  foreach d in array array['2026-10-05','2026-10-06','2026-10-19','2026-10-20']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion) values
      (p1, f,  d + time '14:00', d + time '20:00', d + time '13:30', 'Tcia. Chungará (F)'),
      (p1, f2, d + time '14:00', d + time '20:00', d + time '13:30', 'Retén Chucuyo (F)');
  end loop;

  insert into po_plazos (plan_id, tipo, descripcion, estado, ncu_cumplimiento) values
    (p1, 'acuse_recibo', 'Acuse de recibo "PLAN OPERATIVO N.° 03" (NCU 263840570, "plazo hoy 12:00")', 'cumplido', '263842066');
  insert into po_plazos (plan_id, tipo, descripcion, vence, estado, cumplido_en) values
    (p1, 'labor', 'Labor 1er bloque (05-06.10.2026) — NCU 263854679', '2026-10-07 08:00', 'cumplido', '2026-10-07 08:00');
  insert into po_plazos (plan_id, tipo, descripcion, vence, destinatario) values
    (p1, 'acuse_recibo', 'Acuse de recibo "PLAN OPERATIVO N.° 03" para el 2º bloque — NCU 264729932',
     '2026-10-17 10:00', 'Subprefectura Fronteriza');
  insert into po_plazos (plan_id, tipo, descripcion, vence, al_termino_servicio, destinatario, formato) values
    (p1, 'labor', 'Labor y evaluación 2º bloque: inmediatamente finalizado el servicio del 20.10.2026 — NCU 264733174',
     '2026-10-20 20:00', true, 'Consolidada por el Jefe Tcia. Chungará (F), incluyendo la labor del personal OS7',
     'Labor detallada (controles, fiscalizaciones, procedimientos y resultados) + evaluación según Manual de Planificación Operativa');

  insert into po_contradicciones (plan_id, campo, valor_a, fuente_a, valor_b, fuente_b) values
    (p1, 'PC N°2 · personal SIP 4ta Com.', '2 PNI, 1 AP', 'Resumen General', '4 PNI, 1 AP', 'Anexo N°1'),
    (p1, 'Distribución del personal OS7', '3 PNI + 1 CAN, todos en PC N°1 (CF Chungará)', 'Resumen General y Anexo N°1',
         'Guía canino en CF Chungará y además 2 funcionarios en Retén Chucuyo, km 159', 'Texto del plan (Fase II, Depto. O.S.7)'),
    (p1, 'Total de AP (autos patrulleros)', '14 AP', 'Tabla "Total recursos Zona Arica y Parinacota"', '3 AP (2 propios + 1 OS7)', 'Tablas de recursos propios y especializados');

  -- ═══ P2 · Plan Operativo Fortalecimiento CF Chungará (permanente) ═
  -- Fuente: inicio de la traza DOE NCU 264733174 (Zona Arica y Parinacota)
  insert into po_planes (tipo, titulo, emisor, emisor_detalle, hasta_nueva_orden, recurrencia, supervisor,
                         observaciones, revision, confirmado_en)
  values ('plan_operativo', 'Plan Operativo para el Fortalecimiento del Complejo Fronterizo Chungará', 'zona',
          'Jefatura de Zona Arica y Parinacota, por propuesta del Seremi de Seguridad Pública (correo 01.10.2026)', true,
          'PC1: todas las semanas del mes; Carabineros lunes y martes, 2 semanas al mes. PC2: 2 semanas al mes, lunes y martes, jornada PM. PC3: 1 vez a la semana.',
          'Subprefecto Rural Fronterizo (fiscaliza el cometido)',
          'Plan de corto plazo con 3 puntos de control. En octubre 2026 los PC1 y PC2 se operacionalizan mediante el Plan N°03 de la Subprefectura Fronteriza (05-06 y 19-20.10.2026, lunes y martes). Las acciones del PC1 comenzaron con la PDI apoyada por personal de la Tcia. Chungará (F). El primer operativo del PC3 se informó en Ruta 11-CH km 5 al 8, de 11:00 a 13:00 (fecha no especificada; DOE relacionado NCU 263713539). Monitoreo: Jefe de Zona y Oficina de Planificación y Análisis Criminal de la Plana Mayor. Medida de mediano/largo plazo: traslado del camión escáner desde el CF Chacalluta al CF Chungará.',
          'confirmado', now())
  returning id into p2;

  insert into po_ncu (plan_id, ncu, es_origen, resumen) values
    (p2, '263720703', true,  'Zona remite correo del Seremi de Seguridad Pública (01.10.2026) con el plan; dispone a la Prefectura Arica N°1 operacionalizarlo e informar semanalmente labor y novedades'),
    (p2, '263742155', false, 'Zona dispone el plan: 3 puntos de control, indicadores semanales y medida de mediano plazo. "PLAZO: SÁBADO 03.10.2026; 10:00 HRS."'),
    (p2, '263787791', false, 'Prefectura Arica: para conocimiento y cumplimiento'),
    (p2, '263713539', false, 'DOE relacionado citado en NCU 263720703 (contenido no disponible)');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_instituciones, observaciones, orden)
  values (p2, 'PC1 · Refuerzo en el CF Chungará', 'Complejo Fronterizo Chungará', u_chu, '{PDI}',
          'Todas las semanas del mes; Carabineros lunes y martes, 2 semanas al mes, reforzando la dotación del CF con personal especializado OS7 (binomios caninos)', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota)
  values (p2, f, u_os7, 'Binomios caninos (cantidad no especificada)');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_instituciones, apoyo_detalle, observaciones, orden)
  values (p2, 'PC2 · Controles integrados Retén Chucuyo', 'Ruta 11-CH km 159 (Retén Chucuyo)', u_cuy, '{MTT}',
          'Dotación del Retén Chucuyo junto al Depto. OS7 y el Ministerio de Transportes y Telecomunicaciones',
          '2 semanas del mes, lunes y martes, jornada PM. Complementario al CF Chungará. Control de camiones Arica → Chungará o altiplano para detectar contrabando de salida (camiones chuteros desde ZOFRI)', 2)
  returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota) values (p2, f2, u_os7, 'Participación OS7 (dotación no especificada)');

  insert into po_facciones (plan_id, nombre, lugar, observaciones, orden)
  values (p2, 'PC3 · Controles integrados en Arica', null,
          '1 vez a la semana, por definir en planes operativos de las policías. Posibles lugares: Truck Center Valle de Lluta km 1 (sujeto a coordinación con el operador y Aduanas), antepuerto Empresa Portuaria Arica, Ruta 11-CH km 5 al 8, localidad de Poconchile. Control de camiones hacia Chungará / altiplano', 3);

  insert into po_plazos (plan_id, tipo, descripcion, destinatario) values
    (p2, 'informe_semanal', 'Labor realizada y medición semanal de indicadores, una vez finalizado el servicio (día y hora no especificados)',
     'Oficina de Planificación y Análisis Criminal, Plana Mayor Zona Arica y Parinacota');
  insert into po_plazos (plan_id, tipo, descripcion, vence) values
    (p2, 'otro', 'Plazo indicado en NCU 263742155 sin especificar su objeto ("PLAZO: SÁBADO 03.10.2026; 10:00 HRS."). Verificar si se cumplió', '2026-10-03 10:00');

  insert into po_indicadores (plan_id, nombre, tipo, numerador, denominador, descripcion, orden) values
    (p2, '% cumplimiento', 'porcentaje', 'N° de operativos realizados', 'N° de operativos comprometidos', 'PC1, PC2 y PC3 (medición semanal)', 1),
    (p2, '% participación institucional', 'porcentaje', 'N° de instituciones participantes', 'Total de instituciones comprometidas', 'PC1 y PC3', 2),
    (p2, 'N° de vehículos fiscalizados', 'numero', null, null, 'PC1; en PC2: vehículos fiscalizados en Chucuyo', 3),
    (p2, 'N° de vehículos devueltos a Bolivia', 'numero', null, null, 'PC1 y PC2', 4),
    (p2, 'N° de controles realizados', 'numero', null, null, 'PC2 y PC3', 5),
    (p2, '% incidencias detectadas', 'porcentaje', 'N° de revisiones con hallazgos', 'Total de revisiones', 'PC3', 6),
    (p2, 'Resultados (infracciones o ilícitos pesquisados)', 'numero', null, null, 'PC1, PC2 y PC3', 7);

  -- ═══ P3 · Plan Abreviado N°02 4ta Com. – Operativo Binacional con SUNAT ═
  -- Fuente: Plan_Abreviado_Operativo_Binacional_SUNAT_Oct2026.pdf
  insert into po_planes (tipo, numero, titulo, emisor, emisor_detalle, fecha_emision, mision, inicio, termino,
                         jefe_servicio, supervisor, observaciones, revision, confirmado_en)
  values ('plan_abreviado', '02', 'Operativo Binacional Perú-Chile en coordinación con la Intendencia de Aduana de Tacna (SUNAT)',
          'comisaria', '4ta. Com. Chacalluta (F) — Comisario Tcrl. Nilo A. Morales Riquelme', '2026-10-19',
          'Implementar servicios policiales extraordinarios en el sector fronterizo de la 4ta. Com. Chacalluta (F), en la zona contigua al LPI con el Perú, entre el 19 y el 31.10.2026, en el marco del Operativo Binacional Perú-Chile convocado por SUNAT y autorizado por el Jefe de Zona, para la prevención y detección del contrabando y delitos transnacionales, culminando el 31.10.2026 con la ceremonia de cierre en el Hito Tripartito.',
          '2026-10-19 00:00', '2026-10-31 23:59',
          'Acorde a la distribución de servicios diarios (Etapa 2: Subcomisario de los Servicios)',
          'Subcomisario de los Servicios 4ta. Com. Chacalluta (F) (anexo: Comisario de Servicio)',
          'Controles de identidad preventivos con ingreso obligatorio a la Plataforma de Controles Migratorios de toda persona extranjera fiscalizada; mercancías incautadas a disposición del Servicio Nacional de Aduanas. Monitoreo en SAIT y Gestión AUPOL. Equipo de invierno para el sector altiplánico. Urgencias: Hospital Juan Noé Crevani; sector altiplánico: establecimiento de salud de Putre. El nombramiento de servicios del 19.10.2026 cita este plan como "Plan Abreviado Nro. 02 18/10/26".',
          'confirmado', now())
  returning id into p3;

  insert into po_ncu (plan_id, ncu, es_origen, resumen) values
    (p3, '264759190', true,  'DOE con que el Jefe de Zona autoriza el operativo binacional'),
    (p3, '264709391', false, 'Coordinaciones con SUNAT dispuestas por el Subprefecto Fronterizo'),
    (p3, '264734490', false, 'Coordinaciones con SUNAT dispuestas por el Subprefecto Fronterizo');

  insert into po_etapas (plan_id, nombre, inicio, termino, lugar, tactica, orden)
  values (p3, 'Etapa 1 · Servicios diurnos en el LPI', '2026-10-19 00:00', '2026-10-30 23:59',
          'Sector fronterizo LPI con Perú: CF Chacalluta y CF Visviri',
          'Patrullajes preventivos y controles de identidad y vehiculares en el LPI coordinados con SUNAT; fiscalización de personas, vehículos y carga con vigilancia de pasos no habilitados', 1)
  returning id into e1;
  insert into po_etapas (plan_id, nombre, inicio, termino, lugar, tactica, orden)
  values (p3, 'Etapa 2 · Ceremonia de cierre', '2026-10-31 00:00', '2026-10-31 23:59',
          'Hito Tripartito Perú-Chile-Bolivia, zona altoandina (jurisdicción Tcia. Visviri)',
          'Resguardo del lugar, autoridades, accesos y estacionamientos; presencia policial y protocolar. Hora por confirmar, hasta el término de la ceremonia', 2)
  returning id into e2;

  insert into po_facciones (plan_id, etapa_id, nombre, lugar, apoyo_instituciones, observaciones, orden)
  values (p3, e1, 'Etapa 1 · CF Chacalluta y CF Visviri', 'Complejo Fronterizo Chacalluta y Complejo Fronterizo Visviri', '{SUNAT}',
          'Servicio diurno conforme realidad; presentación conforme coordinación internacional; movilización en vehículo fiscal', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values (p3, f, u_com, 2, 1), (p3, f, u_vis, 2, 1);
  insert into po_servicios (plan_id, faccion_id, etapa_id, inicio, termino, hora_por_confirmar, observaciones)
  values (p3, f, e1, '2026-10-19 00:00', '2026-10-30 23:59', true, 'Diurno; horario conforme coordinación internacional');

  insert into po_facciones (plan_id, etapa_id, nombre, lugar, jefe_faccion, orden)
  values (p3, e2, 'Etapa 2 · Resguardo y protocolo Hito Tripartito', 'Hito Tripartito', 'Subcomisario de los Servicios', 2)
  returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, cap, pni, ap) values (p3, f2, u_com, 1, 1, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, ap) values (p3, f2, u_vis, 1, 5, 1);
  insert into po_servicios (plan_id, faccion_id, etapa_id, inicio, termino, hora_por_confirmar)
  values (p3, f2, e2, '2026-10-31 00:00', '2026-10-31 23:59', true);

  insert into po_plazos (plan_id, tipo, descripcion, vence, formato) values
    (p3, 'evaluacion', 'Labor desarrollada y evaluación', '2026-11-02 15:00', 'Según Manual de Planificación Operativa');

  -- ═══ P4 · Refuerzo Facción Centinela 3 ══════════════════════════
  -- Fuente: REFUERZO CENTINELA 3 SE INFORMA.pdf (NCU 264744370); lugar según nombramiento de servicios 19.10.2026
  insert into po_planes (tipo, titulo, emisor, emisor_detalle, inicio, termino, observaciones, revision, confirmado_en)
  values ('orden_doe', 'Refuerzo Facción Centinela 3', 'subprefectura_fronteriza',
          'Subprefecto Fronterizo Tcrl. Raúl Arismendi, por orden del Jefe de Zona Gral. Álvaro Martínez Vega',
          '2026-10-17 06:00', '2026-10-24 06:00',
          'Coordinación del Jefe de Zona con el Jefe de Área Fronteriza, Gral. (Ej.) Manuel Provis Baker. La 4ta. Com. Chacalluta (F) dispone el personal de Carabineros; se requiere apoyo de la Fuerza de Tarea Arica los días 21, 22 y 23.10. Antecedentes a disposición del Puesto de Mando de la Jefatura de Área Fronteriza. Recibido como informativo.',
          'confirmado', now())
  returning id into p4;

  insert into po_ncu (plan_id, ncu, es_origen, resumen, fecha) values
    (p4, '264734149', true,  'Subprefecto Fronterizo remite la distribución de personal de Carabineros para la Facción Centinela 3 (17 al 23.10.2026)', null),
    (p4, '264744370', false, 'Comisario: para conocimiento y fines procedentes; recepcionado en calidad de informativo', '2026-10-16');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_instituciones, apoyo_detalle, orden)
  values (p4, 'Facción Centinela 3', 'By Pass Chacalluta (según nombramiento de servicios del 19.10.2026)', u_com, '{Ejército}',
          'Días 21, 22 y 23.10: el 2º turno suma personal del Ejército (Fuerza de Tarea Arica), equipado con chaleco reflectante; en la Unidad toma contacto con el Cap. Álvaro García Fernández', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota)
  values (p4, f, u_com, 'Dotación por turno no especificada en el DOE');

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

  insert into po_contradicciones (plan_id, campo, valor_a, fuente_a, valor_b, fuente_b) values
    (p4, 'Horario del 2º turno', '15:00 a 21:00 (domingo 14:00 a 21:00)', 'DOE NCU 264744370',
         '15:00 a 22:00 (2º Centinela N°3 By Pass Chacalluta)', 'Nombramiento de servicios del 19.10.2026');

  -- ═══ P5 · Plan Barrera Norte N°05 Prefectura Arica ══════════════
  -- Fuente: PLAN BARRERA NORTE NRO 5.pdf + traza DOE NCU 264753566
  insert into po_planes (tipo, numero, titulo, emisor, emisor_detalle, fecha_emision, mision, inicio, termino,
                         jefe_servicio, supervisor, personal_total_declarado, observaciones, revision, confirmado_en)
  values ('plan_operativo', '05',
          'Plan Barrera Norte: fiscalización y control de delitos transnacionales y contrabando (cigarrillos, dinero, baterías, especies vegetales, cobre)',
          'prefectura', 'Prefectura Arica N°01 (firma Subprefecto Fronterizo; V°B° Prefecto Crl. Carlos Mesa Gallardo)', '2026-10-16',
          'Ejecutar servicios policiales extraordinarios de Orden y Seguridad y Tránsito focalizados en la Ruta 11-CH, Ruta 5 Norte y rutas secundarias (A-32, A-31/A-201, A-31/319, A-235/A-95), para detectar delitos transnacionales y contrabando transportados en vehículos "chuteros", en los sectores de la 2ª Com. Putre, Retén Chapiquiña, 4ª Com. Chacalluta (F), Tcia. Visviri (F), Tcia. Chungará (F), Retén Tacora (F), Retén Guallatire (F) y Retén Chilcaya (F).',
          '2026-10-22 00:00', '2026-10-23 23:59',
          'Tte. Jorge Reyes Olivares (OS7)',
          '1ª línea de control: Tcrl. Raúl Arismendi Atencio, S.P.F. · 2ª línea de control: Tcrl. Jorge Pohl Marín, Subprefecto de los Servicios (S)',
          41,
          'Presentación: 30 minutos antes de cada servicio en dependencias de cada Unidad o destacamento. Instalación conforme a horarios dispuestos de forma diaria. Magnitud: no determinada. Las facciones pueden modificarse según apreciación de los Comisarios y el Subprefecto Fronterizo. Los Comisarios de la 2ª Com. Putre y 4ª Com. Chacalluta (F) y los Jefes de Tcia. Visviri y Chungará pueden disponer servicios anexos contra el contrabando, informándolos en la evaluación a la S.P.F. Término: reunión en las unidades de origen. El DOE inicial de la Macrozona Norte (NCU 264642399) fijaba los servicios entre el 19 y 23.10.2026.',
          'confirmado', now())
  returning id into p5;

  insert into po_ncu (plan_id, ncu, es_origen, resumen, fecha) values
    (p5, '264642399', true,  'Zona Antofagasta (Coordinador Macrozona Norte): servicios preventivos contra el crimen organizado entre el 19 y 23.10.2026, en 1ª y 2ª línea de control; zonas remiten planes a más tardar el 17.10.2026 10:00', null),
    (p5, '264733278', false, 'Zona Arica y Parinacota remite el Plan Barrera Norte, "que se ejecutará los días 21 y 23 de octubre"', null),
    (p5, '264735217', false, 'Zona dispone la ejecución los días 21 y 23.10; consolidar resultados de la labor en el formato adjunto. PLAZO: sábado 24.10 a las 10:00', null),
    (p5, '264736301', false, 'Prefectura Arica: recabar la información dentro del plazo; estricto cumplimiento de los servicios', null),
    (p5, '264753566', false, 'Comisario (17.10.2026 08:12) al Administrador de Operaciones: para conocimiento y cumplimiento. Instrucción vigente. Adjuntos: plan y FORMATO LABOR.xlsx', '2026-10-17');

  -- 1ª línea de control
  insert into po_facciones (plan_id, nombre, lugar, observaciones, orden)
  values (p5, '1ª línea de control · Despliegue Barrera Norte',
          'Ruta 11-CH km 01 al 192; Ruta 11-CH km 126 (ingreso Putre); Ruta A-31 km 15 a 17; cruce A-31/A-201 (Murmuntani); cruce A-319/A-95; pasos no habilitados Laguna Blanca, Hito XVII y Guacollo',
          'Asignación de unidades por facción no especificada en el plan; se agrupan aquí las unidades de la 1ª línea del Resumen General', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, cap, tte, pni, fz, ap) values
    (p5, f, u_put, 1,    null, 3, 1,    null),
    (p5, f, u_chp, null, null, 2, 1,    null),
    (p5, f, u_com, 1,    null, 2, null, 1),
    (p5, f, u_sip, null, null, 2, null, 1),
    (p5, f, u_vis, null, null, 3, null, 1),
    (p5, f, u_chu, null, 1,    2, null, 1),
    (p5, f, u_tac, null, null, 3, null, 1),
    (p5, f, u_cuy, null, null, 3, 1,    null),
    (p5, f, u_gua, null, null, 3, null, 1),
    (p5, f, u_chi, null, null, 3, null, 1);
  insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
  values (p5, f, '2026-10-22 00:00', '2026-10-23 23:59', '2026-10-21 23:30', 'Dependencias de cada unidad (30 min antes)');

  -- 2ª línea: punto de control Tcia. Carretera Arica
  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, observaciones, orden)
  values (p5, '2ª línea · Punto de control Tcia. Carretera Arica', 'Tenencia Carretera Arica', u_car,
          'OS7 asigna tres funcionarios adicionales para servicios diferenciados en coordinación con el personal de la Tenencia. Servicios habituales desde las 22:00 hasta la normalización', 2)
  returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, ap) values (p5, f2, u_os7, 3, 1);
  insert into po_recursos (plan_id, faccion_id, unidad_id, tte, pni, rp, nota)
  values (p5, f2, u_car, 1, 2, 1, 'Unidad del Resumen General; su asignación a esta facción se deduce del texto del plan');
  foreach d in array array['2026-10-21','2026-10-22','2026-10-23']::date[] loop
    insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
    values (p5, f2, d + time '15:00', d + time '21:00', d + time '14:30', 'Dependencias de cada unidad (30 min antes)');
  end loop;

  -- 2ª línea: Quebrada del Diablo
  insert into po_facciones (plan_id, nombre, lugar, observaciones, orden)
  values (p5, '2ª línea · Quebrada del Diablo', 'Sector Quebrada del Diablo, entre rutas A-191 y A-143, y sectores jurisdiccionales de cada retén',
          'Servicios conjuntos de control y fiscalización para detectar y recuperar vehículos robados y detectar contrabando', 3)
  returning id into f3;
  insert into po_recursos (plan_id, faccion_id, unidad_id, pni, fz) values (p5, f3, u_poc, 3, 1), (p5, f3, u_azp, 3, 1);
  insert into po_servicios (plan_id, faccion_id, inicio, termino, presentacion, lugar_presentacion)
  values (p5, f3, '2026-10-22 00:00', '2026-10-23 23:59', '2026-10-21 23:30', 'Dependencias de cada unidad (30 min antes)');

  insert into po_plazos (plan_id, tipo, descripcion, vence, destinatario, formato) values
    (p5, 'labor', 'Recopilación y consolidación de los resultados de la labor — NCU 264735217', '2026-10-24 10:00',
     'Zona Arica y Parinacota (antecedente para el Comité Policial)', 'FORMATO LABOR.xlsx adjunto al DOE');
  insert into po_plazos (plan_id, tipo, descripcion, destinatario) values
    (p5, 'evaluacion', 'Evaluación con aspectos positivos, negativos y sugerencias, solicitada al término del servicio (plazo no especificado)',
     'Subprefectura Fronteriza (S.P.F.)');

  insert into po_contradicciones (plan_id, campo, valor_a, fuente_a, valor_b, fuente_b) values
    (p5, 'Fechas del servicio', '00:00 del 22.10 a 23:59 del 23.10.2026 (jueves y viernes)', 'Plan Barrera Norte N°05',
         'Días 21 y 23 de octubre', 'DOE NCU 264733278 y 264735217 (Zona)');

  -- ═══ P6 · Emergencia preventiva "Sistema Frontal" ═══════════════
  -- Fuente: EMERGENCIA PREVENTIVA ... SISTEMA FRONTAL.pdf (NCU 264854195)
  insert into po_planes (tipo, titulo, emisor, emisor_detalle, inicio, termino, mision, observaciones, revision, confirmado_en)
  values ('emergencia', 'Emergencia preventiva con motivo del "Sistema Frontal"', 'direccion_nacional',
          'Dirección Nacional de Orden y Seguridad', '2026-10-18 00:00', '2026-10-23 23:59',
          'Monitoreo permanente de las condiciones meteorológicas; identificar y priorizar sectores críticos y puntos de riesgo; servicios extraordinarios de orden y seguridad, control de tránsito y patrullajes preventivos; continuidad operativa; apoyo a SENAPRED y organismos de emergencia; prevenir delitos con ocasión de la emergencia; revisar instalaciones y grupos electrógenos (con carga de combustible), cargo fiscal, equipamiento operativo y tenidas impermeables; difundir las instrucciones a todo el personal dejando constancia escrita en los libros de instrucciones al personal y SVT; informar a la brevedad ante eventuales emergencias.',
          'Decreto Exento N°1.407 de 17.10.2026 declara emergencia preventiva por el "Sistema Frontal" del 18 al 23.10.2026. Alerta meteorológica: precipitaciones entre las regiones de Atacama y Los Lagos; mayor intensidad tarde y noche del martes 20.10.2026 (Coquimbo a Maule). Se rige por el Plan Operativo DIOSCAR N°11 (20.04.2026, vigente hasta nueva orden), que fija la evaluación de la Jefatura de Zona en un plazo no mayor de 3 días tras finalizar los servicios. Suboficial interno: entregar las instrucciones a los jefes de servicio en la población, dejando constancia. Sin plazo de respuesta.',
          'confirmado', now())
  returning id into p6;

  insert into po_ncu (plan_id, ncu, es_origen, resumen, fecha) values
    (p6, '264782435', true,  'Dirección Nacional de Orden y Seguridad: reitera instrucciones y cursos de acción por el Decreto Exento N°1.407; adjunta el Plan DIOSCAR N°11', null),
    (p6, '264789701', false, 'DNOS amplía y reitera instrucciones tras sesión del COGRID técnico; alerta meteorológica 18-23.10.2026', null),
    (p6, '264793381', false, 'Zona Arica y Parinacota: impartir y reiterar instrucciones a todas las unidades', null),
    (p6, '264794631', false, 'Prefectura Arica: el Subprefecto Fronterizo hará lo propio con la 4ta. Com. y sus destacamentos', null),
    (p6, '264824821', false, 'Subprefecto Fronterizo: difundir hasta nivel destacamento con constancia escrita en libros de instrucciones al personal y SVT', null),
    (p6, '264854195', false, 'Comisario (19.10.2026 16:06): difusión a la totalidad del personal; subcomisarios, oficiales y jefes de destacamento reiteran instrucciones. Instrucción vigente', '2026-10-19');
  insert into po_servicios (plan_id, inicio, termino, observaciones)
  values (p6, '2026-10-18 00:00', '2026-10-23 23:59', 'Emergencia preventiva sin facciones definidas');

  -- ═══ P7 · Mesa de coordinación Plan Regional contra el Crimen Organizado ═
  -- Fuente: INFORMA REUNIÓN DE COORDINACIÓN ... CRIMEN ORGANIZADO.pdf (NCU 264647954)
  insert into po_planes (tipo, titulo, emisor, emisor_detalle, inicio, termino, observaciones, revision, confirmado_en)
  values ('mesa_coordinacion', 'Mesa de coordinación Plan Regional contra el Crimen Organizado · octubre 2026', 'prefectura',
          'Acuerdos de la reunión de coordinación del 07.10.2026 informados por el Coordinador (S), Tte. Jorge Reyes (Sección OS7 Arica); difundidos por la Prefectura Arica',
          '2026-10-13 11:00', '2026-10-28 23:59',
          'Se solicita difundir los acuerdos a las unidades de la Prefectura Arica que correspondan. El Comisario solicitó verificar el cumplimiento de las misiones asignadas (NCU 264646698).',
          'confirmado', now())
  returning id into p7;

  insert into po_ncu (plan_id, ncu, es_origen, resumen, fecha) values
    (p7, '264310247', true,  'Sección OS7 Arica (Coordinador subrogante) informa acuerdos y actividades de la reunión del 07.10.2026', null),
    (p7, '264316588', false, 'Prefectura Arica remite para conocimiento de unidades especializadas y 4ta. Com.: téngase presente y cúmplase', null),
    (p7, '264318390', false, 'Comisario: para conocimiento y fines pertinentes a sus áreas de gestión', null),
    (p7, '264646698', false, 'Comisario: verificar el cumplimiento de las misiones asignadas', null),
    (p7, '264647954', false, 'Subcomisario de los Servicios (15.10.2026 17:28): el plan del día finaliza a las 19:00; la labor se enviará al día siguiente según lo informado por la SIP', '2026-10-15');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_instituciones, apoyo_detalle, orden)
  values (p7, '6 · Operativo robo de cables', 'Sector previamente focalizado (no especificado)', '{PDI}', 'A cargo de la PDI y la Sección OS9 Arica', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id) values (p7, f, u_os9);
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-13 11:00', '2026-10-13 13:00');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_instituciones, apoyo_detalle, orden)
  values (p7, '2 · Fiscalización vehículos de carga pesada', 'Ruta 11-CH, km 69', u_com, '{SAG,SII}',
          'Patrulla OS7 Arica y personal de la 4ta. Com.; se invita al SAG y al SII', 2)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota) values
    (p7, f, u_os7, 'Una patrulla'),
    (p7, f, u_com, 'Personal no especificado; la labor la informa la SIP 4ta. Com.');
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-15 15:00', '2026-10-15 19:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_instituciones, apoyo_detalle, orden)
  values (p7, '1 · Controles vehiculares Ruta A-143', 'Ruta A-143, San Miguel de Azapa a Poconchile', '{PDI}', 'La PDI coordina directamente con el S.E.B.V. Arica', 3)
  returning id into f;
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-20 02:00', '2026-10-20 06:00');

  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_detalle, orden)
  values (p7, '4 · Fiscalizaciones en CF Chacalluta', 'Complejo Fronterizo Chacalluta', u_com,
          'Carabineros participa como institución vinculante; ejecución a cargo de la 4ta. Com.', 4)
  returning id into f;
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-20 22:00', '2026-10-21 00:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_detalle, orden)
  values (p7, '3 · Operativo Ruta A-235', 'Ruta A-235, Guallatire', 'Una patrulla OS7 y una patrulla OS9 Arica', 5)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota) values (p7, f, u_os7, 'Una patrulla'), (p7, f, u_os9, 'Una patrulla');
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-21 12:00', '2026-10-21 16:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_instituciones, apoyo_detalle, orden)
  values (p7, '5 · Operativo Quebrada Encantada (2ª fase)', 'Sector Quebrada Encantada, sector del agro y alrededores', '{SAG,SII}',
          'Participa Sección OS7 Arica; se invita al SAG y al SII; si es posible, Patrulla Centauro de la Repartición', 6)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id) values (p7, f, u_os7);
  insert into po_servicios (plan_id, faccion_id, inicio, termino) values (p7, f, '2026-10-26 06:00', '2026-10-26 10:00');

  insert into po_facciones (plan_id, nombre, lugar, apoyo_instituciones, orden)
  values (p7, '7 · Capacitación lavado de activos', null, '{PDI}', 7)
  returning id into f;
  insert into po_servicios (plan_id, faccion_id, inicio, termino, hora_por_confirmar, observaciones)
  values (p7, f, '2026-10-28 00:00', '2026-10-28 23:59', true, 'Charla de la PDI; lugar y hora los informa la PDI');

  insert into po_plazos (plan_id, tipo, descripcion, destinatario) values
    (p7, 'labor', 'Labor de la fiscalización del 15.10.2026 (km 69): "se enviará el día de mañana" (16.10.2026, hora no especificada). Verificar si se remitió',
     'Comisario 4ta. Com. Chacalluta (F)');

  -- ═══ P8 · Campeonato Internacional de Ciclismo Arica-Tacna ══════
  -- Fuente: REUNION BILATERAL CARRERA CICLISTICA.pdf (NCU 264856380)
  insert into po_planes (tipo, titulo, emisor, emisor_detalle, inicio, termino, observaciones, revision, confirmado_en)
  values ('evento_preparacion', 'Campeonato Internacional de Ciclismo de Ruta Arica-Tacna', 'prefectura',
          'Prefectura Arica (dispone coordinar y planificar los servicios)', '2026-12-11 00:00', '2026-12-13 23:59',
          'Propuesta presentada en reunión bilateral del 14.10.2026 (CF Chacalluta). Programa: contrarreloj en territorio chileno y prueba de gran fondo con cruce de frontera (deportistas chilenos, peruanos y eventualmente bolivianos). Logística propuesta: zona "burbuja" de control previo de competidores, bicicletas y vehículos de apoyo; identificación electrónica con chips y monitoreo en tiempo real. Perú indica que los controles migratorios deben hacerse en puntos habilitados. Pendientes: autorización de procedimientos migratorios y aduaneros; circuito definitivo en Chile y Perú; despliegue policial, servicios de emergencia y personal municipal; validación del sistema de control e identificación; categorías, cupos y cronograma operativo.',
          'confirmado', now())
  returning id into p8;

  insert into po_ncu (plan_id, ncu, es_origen, resumen, fecha) values
    (p8, '264480825', true,  'Prefectura dispone al Comisario participar en la reunión bilateral de coordinación del 14.10.2026, 12:00 hrs, CF Chacalluta', null),
    (p8, '264481148', false, 'Prefectura: informar los temas tratados una vez finalizada la reunión', null),
    (p8, '264483472', false, 'Comisario: dar cumplimiento a lo dispuesto', null),
    (p8, '264706131', false, 'Subcomisario de los Servicios informa los temas tratados', null),
    (p8, '264706733', false, 'Comisario informa a la Prefectura los temas tratados', null),
    (p8, '264799905', false, 'Prefectura: coordinar y disponer la planificación de los servicios del campeonato', null),
    (p8, '264856380', false, 'Comisario (19.10.2026 16:19): para conocimiento y fines; recepcionado como informativo', '2026-10-19');

  insert into po_etapas (plan_id, nombre, inicio, termino, orden) values
    (p8, 'Lanzamiento', '2026-12-11 00:00', '2026-12-11 23:59', 1),
    (p8, 'Competencia: contrarreloj (Chile) y gran fondo con cruce de frontera', '2026-12-12 00:00', '2026-12-13 23:59', 2);

  insert into po_plazos (plan_id, tipo, descripcion, destinatario) values
    (p8, 'remision_plan', 'Coordinar y disponer la planificación de los servicios (NCU 264799905); sin plazo indicado', 'Prefectura Arica');

  -- ═══ Plan DIOSCAR N°11 (marco nacional) — queda en "Por revisar" ═
  -- Fuente: PLAN NRO. 11 FENOMENOS NATURALES ... 2026.pdf (adjunto al DOE NCU 264854195)
  insert into po_planes (tipo, numero, titulo, emisor, emisor_detalle, fecha_emision, hasta_nueva_orden, mision,
                         observaciones, revision)
  values ('emergencia', '11', 'Plan Operativo DIOSCAR ante emergencias por fenómenos naturales, tales como frente de mal tiempo, a nivel nacional',
          'direccion_nacional', 'Dirección Nacional de Orden y Seguridad (Gral. Insp. Rodrigo Espinoza Olea)', '2026-04-20', true,
          'Implementar servicios policiales extraordinarios de orden y seguridad y control de tránsito vial, orientados a la prevención y respuesta ante contingencias por fenómenos naturales, en coordinación con las instituciones pertinentes, manteniendo presencia activa durante la emergencia para prevenir delitos contra las personas y la propiedad.',
          'Plan marco: vigente desde su publicación hasta nueva orden de la DNOS. Recibido como adjunto del DOE NCU 264854195 (emergencia "Sistema Frontal"). Evaluación de cada Jefatura de Zona en plazo no mayor de 3 días tras finalizar los servicios, al Depto. de Planificación y Control de Gestión con copia a la DNOS. Las Zonas debían remitir su plan operativo a más tardar el 22.04.2026. Instrucciones relevantes: oficial de enlace con SENAPRED; mantener canaletas, techumbres y evacuación de aguas lluvia de los cuarteles; plan de citación del personal actualizado; el Subprefecto de los Servicios monitorea meteochile.cl y senapred.cl (alertas verde, amarilla y roja). Queda en "Por revisar" para decidir si se mantiene como plan vigente en el módulo.',
          'por_revisar');

  raise notice 'Carga realizada: 8 planes confirmados y 1 en "Por revisar".';
end $$;

commit;
