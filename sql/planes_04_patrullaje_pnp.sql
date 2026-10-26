-- ═══════════════════════════════════════════════════════════════
-- SIGO — Control de Planes Operativos
-- 04 · Patrullaje conjunto con la Policía Nacional del Perú (DOE NCU 265218358)
-- Ejecutar en Supabase → SQL Editor. Es idempotente: si el NCU ya existe, no hace nada.
-- Queda en "Por revisar": confirmarlo desde su ficha para activarlo.
-- ═══════════════════════════════════════════════════════════════

begin;
set local time zone 'America/Santiago';

do $$
declare
  u_com uuid; u_vis uuid;
  p uuid; f uuid; f2 uuid;
begin
  if exists (select 1 from po_ncu where ncu = '265218358') then
    raise notice 'El patrullaje conjunto PNP ya estaba cargado; no se hizo nada.';
    return;
  end if;

  select id into u_com from po_unidades where sigla = '4ta Com.';
  select id into u_vis from po_unidades where sigla = 'Tcia. Visviri';

  insert into po_planes (tipo, titulo, emisor, emisor_detalle, mision, inicio, termino, observaciones, revision)
  values ('orden_doe', 'Patrullaje conjunto con la Policía Nacional del Perú (PNP)', 'subprefectura_fronteriza',
          'Subprefecto Fronterizo Tcrl. Raúl Arismendi, Prefectura Arica',
          'Servicio conjunto con personal de la Policía Nacional del Perú para contrarrestar delitos transnacionales, tales como contrabando, tráfico de drogas y trata de personas, en cumplimiento de los compromisos adquiridos en la VIII Reunión de Altos Mandos Policiales y Unidades Especializadas RAMPOL Chile-Perú.',
          '2026-10-25 06:00', '2026-10-27 21:00',
          'Destinatarios del DOE: Administrador de Operaciones y Subof. Mayor Moisés Hernández, Jefe de Tenencia (S). Horarios del DOE en hora de Chile; en Perú corresponden a 2 horas menos. Al finalizar cada servicio: acta del servicio conjunto, set fotográfico y detalle de la labor realizada.',
          'por_revisar')
  returning id into p;

  insert into po_ncu (plan_id, ncu, es_origen, resumen, fecha) values
    (p, '265216413', true,  'Subprefecto Fronterizo dispone servicio conjunto con la PNP (2 servicios); acta, set fotográfico y labor al finalizar; acuse de recibo con la frase "SERVICIO CONJUNTO PNP", plazo hoy 17:00', null),
    (p, '265218358', false, 'Comisario (23.10.2026 15:27): para conocimiento y cumplimiento; reitera remitir acta, set fotográfico y labor al finalizar. Instrucción vigente', '2026-10-23');

  -- Servicio N°1
  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_instituciones, apoyo_detalle, orden)
  values (p, 'Servicio N°1 · Hito Tripartito', 'Punto de encuentro: Tripartito', u_vis, '{PNP}',
          'Servicio conjunto con personal de la Policía Nacional del Perú', 1)
  returning id into f;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota) values (p, f, u_vis, 'Dotación no especificada en el DOE');
  insert into po_servicios (plan_id, faccion_id, inicio, termino, institucion, observaciones)
  values (p, f, '2026-10-25 06:00', '2026-10-25 08:00', 'Carabineros (Tcia. Visviri) + PNP', 'Horario Perú: 04:00 a 06:00');

  -- Servicio N°2
  insert into po_facciones (plan_id, nombre, lugar, unidad_cargo_id, apoyo_instituciones, apoyo_detalle, orden)
  values (p, 'Servicio N°2 · Hitos 10 al 18', 'Punto de encuentro: Hitos del 10 al 18', u_com, '{PNP}',
          'Servicio conjunto con personal de la Policía Nacional del Perú. Base: 4ta. Com. Chacalluta (F)', 2)
  returning id into f2;
  insert into po_recursos (plan_id, faccion_id, unidad_id, nota) values (p, f2, u_com, 'Dotación no especificada en el DOE');
  insert into po_servicios (plan_id, faccion_id, inicio, termino, institucion, observaciones)
  values (p, f2, '2026-10-27 19:00', '2026-10-27 21:00', 'Carabineros (4ta. Com.) + PNP', 'Horario Perú: 17:00 a 19:00');

  -- Plazos
  insert into po_plazos (plan_id, tipo, descripcion, destinatario) values
    (p, 'acuse_recibo', 'Acuse de recibo conforme con la frase "SERVICIO CONJUNTO PNP" — NCU 265216413, "plazo hoy 17:00" (fecha del DOE inicial no indicada)',
     'Subprefectura Fronteriza');
  insert into po_plazos (plan_id, tipo, descripcion, vence, al_termino_servicio, destinatario, formato) values
    (p, 'labor', 'Servicio N°1 (25.10.2026): acta, set fotográfico y labor una vez finalizado el servicio', '2026-10-25 08:00', true,
     'Subprefectura Fronteriza', 'Acta del servicio conjunto + set fotográfico + detalle de la labor realizada'),
    (p, 'labor', 'Servicio N°2 (27.10.2026): acta, set fotográfico y labor una vez finalizado el servicio', '2026-10-27 21:00', true,
     'Subprefectura Fronteriza', 'Acta del servicio conjunto + set fotográfico + detalle de la labor realizada');

  raise notice 'Patrullaje conjunto PNP cargado en "Por revisar".';
end $$;

commit;
