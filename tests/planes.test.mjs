// Pruebas de la lógica pura del módulo de Planes Operativos.
// Ejecutar con:  node --test tests/planes.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

// Carga js/planes.js con un SIGO mínimo (las funciones probadas no usan la base de datos)
const ctx = { window: {}, SIGO: { db: {} }, Intl, Date, console, document: {} };
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(new URL('../js/planes.js', import.meta.url), 'utf8'), ctx);
const PO = ctx.window.PO;

// Fecha de referencia de las pruebas: lunes 19.10.2026 17:00 (Chile, UTC-3)
const AHORA = new Date('2026-10-19T20:00:00Z');
const srv = (ini, fin) => ({ inicio: PO.deInput(ini), termino: PO.deInput(fin) });

test('formato chileno de fecha y hora en America/Santiago', () => {
  assert.equal(PO.fFecha('2026-10-19T17:00:00Z'), '19.10.2026');
  assert.equal(PO.fHora('2026-10-19T17:00:00Z'), '14:00');
  assert.equal(PO.fFechaHora('2026-10-20T03:30:00Z'), '20.10.2026 00:30');
  assert.equal(PO.fFecha('2026-10-02'), '02.10.2026', 'fecha sin hora no se desplaza por zona horaria');
});

test('conversión hora local ↔ UTC respeta el horario de verano', () => {
  assert.equal(PO.deInput('2026-10-19T14:00'), '2026-10-19T17:00:00.000Z', 'octubre: UTC-3');
  assert.equal(PO.deInput('2026-07-15T14:00'), '2026-07-15T18:00:00.000Z', 'julio: UTC-4');
  for (const s of ['2026-10-19T14:00', '2026-07-15T08:30', '2026-12-31T23:59', '2026-09-07T00:00'])
    assert.equal(PO.aInput(PO.deInput(s)), s, `ida y vuelta ${s}`);
});

test('lectura de fechas dd.mm.aaaa', () => {
  assert.equal(PO.parseFechaCL('19.10.2026'), '2026-10-19');
  assert.equal(PO.parseFechaCL('2/11/2026'), '2026-11-02');
  assert.equal(PO.parseFechaCL('31.02.2026'), null, 'fecha inexistente');
  assert.equal(PO.parseFechaCL('texto'), null);
  assert.equal(PO.diaSemana('2026-10-19'), 1, '19.10.2026 es lunes');
  assert.equal(PO.diaSemana('2026-10-18'), 7, '18.10.2026 es domingo');
  assert.equal(PO.sumarDias('2026-10-31', 1), '2026-11-01');
});

test('estado calculado de los planes de la semilla al 19.10.2026 17:00', () => {
  const conf = { revision: 'confirmado', plazos: [] };
  const p1 = { ...conf, servicios: ['05', '06', '19', '20'].map(d => srv(`2026-10-${d}T14:00`, `2026-10-${d}T20:00`)),
               plazos: [{ tipo: 'labor', estado: 'pendiente', vence: PO.deInput('2026-10-20T20:00') }] };
  const p3 = { ...conf, servicios: [srv('2026-10-19T00:00', '2026-10-30T23:59')] };
  const p4 = { ...conf, servicios: [srv('2026-10-19T15:00', '2026-10-19T21:00'), srv('2026-10-23T22:00', '2026-10-24T06:00')] };
  const p5 = { ...conf, servicios: [srv('2026-10-21T15:00', '2026-10-21T21:00'), srv('2026-10-22T00:00', '2026-10-23T23:59')] };
  const p6 = { ...conf, servicios: [srv('2026-10-18T00:00', '2026-10-23T23:59')] };
  const p7 = { ...conf, servicios: [srv('2026-10-20T02:00', '2026-10-20T06:00')] };
  const p8 = { ...conf, servicios: [], inicio: PO.deInput('2026-12-11T00:00'), termino: PO.deInput('2026-12-13T23:59') };
  const p2 = { ...conf, servicios: [], hasta_nueva_orden: true };

  for (const [n, p] of Object.entries({ p1, p3, p4, p6 })) assert.equal(PO.estadoPlan(p, AHORA), 'en_curso', n);
  for (const [n, p] of Object.entries({ p5, p7, p8 })) assert.equal(PO.estadoPlan(p, AHORA), 'proximo', n);
  assert.equal(PO.estadoPlan(p2, AHORA), 'en_curso', 'P2 vigente hasta nueva orden');

  // P1 al cerrar el 20.10 a las 20:00 queda pendiente de labor
  assert.equal(PO.estadoPlan(p1, new Date(PO.deInput('2026-10-20T20:01'))), 'pendiente_labor');
  p1.plazos[0].estado = 'cumplido';
  assert.equal(PO.estadoPlan(p1, new Date(PO.deInput('2026-10-20T20:01'))), 'finalizado');
});

test('bandeja y cierre tienen prioridad sobre las fechas', () => {
  const s = [srv('2026-10-19T00:00', '2026-10-20T00:00')];
  assert.equal(PO.estadoPlan({ revision: 'por_revisar', servicios: s }, AHORA), 'por_revisar',
    'un plan sin confirmar no se activa aunque esté en fecha');
  assert.equal(PO.estadoPlan({ revision: 'confirmado', cerrado: true, servicios: s }, AHORA), 'cerrado');
});

test('semáforo de plazos', () => {
  const z = v => ({ estado: 'pendiente', vence: PO.deInput(v) });
  assert.equal(PO.semaforoPlazo(z('2026-10-19T10:00'), AHORA).clave, 'vencido');
  assert.equal(PO.semaforoPlazo(z('2026-10-19T23:00'), AHORA).clave, 'hoy');
  assert.equal(PO.semaforoPlazo(z('2026-10-21T10:00'), AHORA).clave, '48h');
  assert.equal(PO.semaforoPlazo(z('2026-10-24T10:00'), AHORA).clave, 'a_tiempo', 'plazo labor P5');
  assert.equal(PO.semaforoPlazo({ estado: 'cumplido', vence: null }, AHORA).clave, 'cumplido');
  assert.equal(PO.semaforoPlazo({ estado: 'pendiente', vence: null }, AHORA).clave, 'sin_fecha');
});

test('suma de recursos distingue "no especificado" de cero', () => {
  const r = PO.sumaRecursos([{ pns: 1, pni: 2, ap: 1 }, { pni: 3, can: 1, ap: 1 }]);
  assert.equal(r.personal, 6);
  assert.equal(r.especificado, true);
  assert.equal(r.medios.ap, 2);
  assert.equal(PO.textoMedios(r.medios), '2 AP · 1 CAN');
  assert.equal(PO.sumaRecursos([{ nota: 'Dotación no especificada' }]).especificado, false);
});

test('el escape de HTML evita inyección en títulos', () => {
  assert.equal(PO.esc('<img src=x onerror=alert(1)>'), '&lt;img src=x onerror=alert(1)&gt;');
  assert.match(PO.val(null), /No especificado/);
});
