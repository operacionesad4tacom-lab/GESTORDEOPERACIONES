// ═══════════════════════════════════════════════
// SIGO — Configuración Supabase
// ⚠️ REEMPLAZA estos valores con los tuyos de Supabase
// ═══════════════════════════════════════════════

const SUPABASE_URL = 'https://hkqyzfoxucusboloqitr.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrcXl6Zm94dWN1c2JvbG9xaXRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4NTIxMjksImV4cCI6MjA4NzQyODEyOX0.4DGq5w2-T0sDiGkHctYNVx61hyQvHbKxQ8ppUQGC3o8';

// Carga la librería de Supabase (debe estar incluida en el HTML)
const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_KEY);

// ─── AUTH ────────────────────────────────────────
async function login(email, password) {
  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

async function logout() {
  await db.auth.signOut();
  window.location.href = 'login.html';
}

async function getUser() {
  const { data } = await db.auth.getUser();
  return data?.user || null;
}

async function getUserProfile(userId) {
  const { data } = await db.from('users').select('*').eq('id', userId).single();
  return data;
}

// ─── TAREAS ──────────────────────────────────────
async function getTareas(filtros = {}) {
  let q = db.from('tareas').select(`
    *, 
    responsable:users!responsable_id(nombre, grado),
    responsable_sec:users!responsable_secundario_id(nombre, grado)
  `).eq('activa', true);
  if (filtros.estado)    q = q.eq('estado', filtros.estado);
  if (filtros.area)      q = q.eq('area', filtros.area);
  if (filtros.prioridad) q = q.eq('prioridad', filtros.prioridad);
  if (filtros.tipo)      q = q.eq('tipo', filtros.tipo);
  const { data, error } = await q.order('hora_limite');
  if (error) throw error;
  return data || [];
}

async function getTareasDelDia(fecha) {
  const d = new Date(fecha);
  const diaSemana = d.getDay() === 0 ? 7 : d.getDay(); // 1=Lun, 7=Dom
  const diaMes = d.getDate();

  const { data, error } = await db.from('tareas').select(`
    *, 
    responsable:users!responsable_id(nombre, grado)
  `)
  .eq('activa', true)
  .or(`tipo.eq.diaria,and(tipo.eq.semanal,dia_semana.eq.${diaSemana}),and(tipo.eq.mensual,dia_mes.eq.${diaMes}),and(tipo.eq.quincenal,dia_mes.in.(1,15)),and(tipo.eq.extraordinaria,fecha_programada.eq.${fecha})`)
  .order('hora_limite');

  if (error) throw error;
  return data || [];
}

async function crearTarea(tarea) {
  const { data, error } = await db.from('tareas').insert([tarea]).select().single();
  if (error) throw error;
  return data;
}

async function actualizarTarea(id, cambios) {
  cambios.updated_at = new Date().toISOString();
  const { data, error } = await db.from('tareas').update(cambios).eq('id', id).select().single();
  if (error) throw error;
  return data;
}

async function actualizarEstadoTarea(id, estado, userId) {
  const cambios = { estado, updated_at: new Date().toISOString() };
  if (estado === 'finalizada') cambios.ultima_realizacion = new Date().toISOString();
  await actualizarTarea(id, cambios);
  await registrarMovimiento(userId, 'tarea', id, `estado_${estado}`, `Estado cambiado a ${estado}`);
}

// ─── EJECUCIONES DIARIAS ─────────────────────────────────────
// Registra que una tarea recurrente fue completada en una fecha específica

async function getEjecucionesDelDia(fecha) {
  const { data, error } = await db.from('ejecuciones_tarea')
    .select(`*, realizada_por:users!realizada_por(nombre, grado)`)
    .eq('fecha', fecha);
  if (error) throw error;
  return data || [];
}

async function getEjecucionesPorTarea(tareaId, limite = 30) {
  const { data, error } = await db.from('ejecuciones_tarea')
    .select(`*, realizada_por:users!realizada_por(nombre, grado)`)
    .eq('tarea_id', tareaId)
    .order('fecha', { ascending: false })
    .limit(limite);
  if (error) throw error;
  return data || [];
}

async function registrarEjecucion(tareaId, userId, observaciones = '', fecha = null) {
  const fechaUso = fecha || new Date().toISOString().split('T')[0];
  // Upsert: si ya existe para ese día, actualiza; si no, inserta
  const { data, error } = await db.from('ejecuciones_tarea').upsert([{
    tarea_id: tareaId,
    fecha: fechaUso,
    realizada_por: userId,
    observaciones
  }], { onConflict: 'tarea_id,fecha' }).select().single();
  if (error) throw error;
  // Actualizar ultima_realizacion en la tarea
  await db.from('tareas').update({
    ultima_realizacion: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }).eq('id', tareaId);
  await registrarMovimiento(userId, 'tarea', tareaId, 'ejecucion_registrada',
    `Ejecutada el ${fechaUso}${observaciones ? ': ' + observaciones : ''}`);
  return data;
}

async function eliminarEjecucion(tareaId, fecha) {
  const { error } = await db.from('ejecuciones_tarea')
    .delete().eq('tarea_id', tareaId).eq('fecha', fecha);
  if (error) throw error;
}

async function archivarTarea(id, userId) {
  await actualizarTarea(id, { activa: false, estado: 'archivada' });
  await registrarMovimiento(userId, 'tarea', id, 'archivada', 'Tarea archivada');
}

// ─── SISTEMA DE DEUDAS ───────────────────────────────────
// Una "deuda" es un registro de que una tarea recurrente tocaba
// ejecutarse en una fecha específica y no fue ejecutada.

/**
 * Verifica si una fecha dada corresponde a una tarea según su tipo.
 * Centraliza la lógica de recurrencia para usarla en la generación de deudas.
 */
function tareaTocabaEnFecha(tarea, fecha) {
  const d = new Date(fecha + 'T12:00:00');
  const diaSemana = d.getDay() === 0 ? 7 : d.getDay(); // 1=Lun, 7=Dom
  const diaMes = d.getDate();
  switch (tarea.tipo) {
    case 'diaria':     return true;
    case 'semanal':    return tarea.dia_semana == diaSemana;
    case 'mensual':    return tarea.dia_mes == diaMes;
    case 'quincenal':  return diaMes === 1 || diaMes === 15;
    default:           return false; // extraordinarias no generan deuda
  }
}

/**
 * Obtiene todas las deudas pendientes (sin resolver).
 * Incluye datos de la tarea asociada.
 */
async function getDeudasPendientes() {
  const { data, error } = await db.from('deudas_tarea')
    .select(`
      *,
      tarea:tareas!tarea_id(
        id, titulo, tipo, area, prioridad, hora_limite,
        responsable:users!responsable_id(nombre, grado)
      )
    `)
    .eq('resuelta', false)
    .order('fecha_debida', { ascending: true }); // las más antiguas primero
  if (error) throw error;
  return data || [];
}

/**
 * Obtiene deudas resueltas (para historial / auditoría).
 */
async function getDeudasResueltas(limite = 50) {
  const { data, error } = await db.from('deudas_tarea')
    .select(`
      *,
      tarea:tareas!tarea_id(id, titulo, tipo, area),
      resuelta_por_user:users!resuelta_por(nombre, grado)
    `)
    .eq('resuelta', true)
    .order('resuelta_en', { ascending: false })
    .limit(limite);
  if (error) throw error;
  return data || [];
}

/**
 * Resuelve una deuda: la marca como resuelta Y crea la ejecución
 * en la fecha original para que el historial quede completo.
 */
async function resolverDeuda(deudaId, userId, observaciones = '') {
  // 1. Obtener la deuda
  const { data: deuda, error: errDeuda } = await db.from('deudas_tarea')
    .select('*').eq('id', deudaId).single();
  if (errDeuda) throw errDeuda;

  // 2. Registrar ejecución en la fecha original (upsert para evitar duplicados)
  await db.from('ejecuciones_tarea').upsert([{
    tarea_id: deuda.tarea_id,
    fecha: deuda.fecha_debida,
    realizada_por: userId,
    observaciones: observaciones || 'Cuenta registrada como cumplida (deuda resuelta)'
  }], { onConflict: 'tarea_id,fecha' });

  // 3. Marcar la deuda como resuelta
  const { error } = await db.from('deudas_tarea').update({
    resuelta: true,
    resuelta_por: userId,
    resuelta_en: new Date().toISOString(),
    observaciones
  }).eq('id', deudaId);
  if (error) throw error;

  // 4. Actualizar ultima_realizacion en la tarea
  await db.from('tareas').update({
    ultima_realizacion: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }).eq('id', deuda.tarea_id);

  // 5. Registrar en historial
  await registrarMovimiento(userId, 'tarea', deuda.tarea_id, 'deuda_resuelta',
    `Deuda del ${deuda.fecha_debida} marcada como cumplida${observaciones ? ': ' + observaciones : ''}`);
}

/**
 * Genera las deudas para el período no procesado.
 * Se llama al iniciar la app cada día. Si ya se procesó hoy, no hace nada.
 * Revisa los últimos 30 días buscando tareas sin ejecución.
 */
async function generarDeudasPendientes() {
  const hoy = new Date().toISOString().split('T')[0];

  // Verificar si hoy ya fue procesado
  try {
    const { data: procesado } = await db.from('deudas_procesadas')
      .select('fecha').eq('fecha', hoy).single();
    if (procesado) return { generadas: 0, yaExistia: true };
  } catch {
    // No existe el registro → proceder a generar
  }

  // Cargar todas las tareas recurrentes activas
  const { data: tareas, error: errTareas } = await db.from('tareas')
    .select('id, titulo, tipo, dia_semana, dia_mes, activa')
    .eq('activa', true)
    .in('tipo', ['diaria', 'semanal', 'mensual', 'quincenal']);
  if (errTareas || !tareas?.length) {
    // Marcar como procesado igual para no reintentar en cada recarga
    await db.from('deudas_procesadas').insert([{ fecha: hoy }]);
    return { generadas: 0, yaExistia: false };
  }

  // Construir rango de fechas: últimos 30 días (sin incluir hoy)
  const fechas = [];
  for (let i = 30; i >= 1; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    fechas.push(d.toISOString().split('T')[0]);
  }

  // Cargar ejecuciones de ese período de una sola vez (eficiente)
  const { data: ejecuciones } = await db.from('ejecuciones_tarea')
    .select('tarea_id, fecha')
    .gte('fecha', fechas[0])
    .lte('fecha', hoy);

  // Cargar deudas ya existentes del período (para no duplicar)
  const { data: deudasExistentes } = await db.from('deudas_tarea')
    .select('tarea_id, fecha_debida')
    .gte('fecha_debida', fechas[0]);

  // Sets para búsqueda O(1)
  const ejSet = new Set((ejecuciones || []).map(e => `${e.tarea_id}|${e.fecha}`));
  const deudaSet = new Set((deudasExistentes || []).map(d => `${d.tarea_id}|${d.fecha_debida}`));

  // Detectar combinaciones tarea+fecha sin ejecución y sin deuda registrada
  const nuevasDeudas = [];
  for (const fecha of fechas) {
    for (const tarea of tareas) {
      if (!tareaTocabaEnFecha(tarea, fecha)) continue;
      const key = `${tarea.id}|${fecha}`;
      if (ejSet.has(key)) continue;    // ya fue ejecutada
      if (deudaSet.has(key)) continue; // ya tiene deuda registrada
      nuevasDeudas.push({
        tarea_id: tarea.id,
        fecha_debida: fecha,
        tipo_tarea: tarea.tipo,
        resuelta: false
      });
    }
  }

  // Insertar en lotes para no saturar la API
  let generadas = 0;
  if (nuevasDeudas.length > 0) {
    const LOTE = 100;
    for (let i = 0; i < nuevasDeudas.length; i += LOTE) {
      const lote = nuevasDeudas.slice(i, i + LOTE);
      const { error } = await db.from('deudas_tarea')
        .upsert(lote, { onConflict: 'tarea_id,fecha_debida', ignoreDuplicates: true });
      if (!error) generadas += lote.length;
    }
  }

  // Marcar hoy como procesado
  await db.from('deudas_procesadas')
    .upsert([{ fecha: hoy }], { onConflict: 'fecha', ignoreDuplicates: true });

  return { generadas, yaExistia: false };
}

/**
 * Fuerza el reprocesamiento del día actual (útil si se agregan tareas nuevas).
 * Elimina el registro de deudas_procesadas para hoy y regenera.
 */
async function forzarRegeneracionDeudas() {
  const hoy = new Date().toISOString().split('T')[0];
  await db.from('deudas_procesadas').delete().eq('fecha', hoy);
  return await generarDeudasPendientes();
}

// ─── DOCUMENTOS DOE ──────────────────────────────
async function getDocumentos(filtros = {}) {
  let q = db.from('documentos').select(`
    *,
    asignado:users!asignado_a(nombre, grado),
    creador:users!creado_por(nombre, grado)
  `).eq('activa', true).is('documento_padre_id', null);

  if (filtros.estado) q = q.eq('estado', filtros.estado);
  const { data, error } = await q.order('fecha_recepcion', { ascending: false });
  if (error) throw error;
  return data || [];
}

async function getDocumento(id) {
  const { data, error } = await db.from('documentos').select(`
    *,
    asignado:users!asignado_a(nombre, grado),
    creador:users!creado_por(nombre, grado),
    hijos:documentos!documento_padre_id(
      *,
      asignado:users!asignado_a(nombre, grado)
    )
  `).eq('id', id).single();
  if (error) throw error;
  return data;
}

async function crearDocumento(doc) {
  const { data, error } = await db.from('documentos').insert([doc]).select().single();
  if (error) throw error;
  return data;
}

async function tomarDocumento(id, userId) {
  await db.from('documentos').update({
    asignado_a: userId,
    estado: 'en_tramite',
    updated_at: new Date().toISOString()
  }).eq('id', id);
  await registrarMovimiento(userId, 'documento', id, 'tomado', 'Documento tomado');
}

async function actualizarEstadoDocumento(id, estado, userId) {
  await db.from('documentos').update({ estado, updated_at: new Date().toISOString() }).eq('id', id);
  await registrarMovimiento(userId, 'documento', id, `estado_${estado}`, `Estado cambiado a ${estado}`);
}

async function verificarConsolidacion(padreId, userId) {
  const { data: hijos } = await db.from('documentos')
    .select('estado').eq('documento_padre_id', padreId);
  if (!hijos || hijos.length === 0) return;
  const todosRespondidos = hijos.every(h => h.estado === 'respondido');
  const algunoRespondido = hijos.some(h => h.estado === 'respondido');
  if (todosRespondidos) {
    await actualizarEstadoDocumento(padreId, 'listo', userId);
  } else if (algunoRespondido) {
    await actualizarEstadoDocumento(padreId, 'parcial', userId);
  }
}

// ─── RUTINAS ─────────────────────────────────────
async function getRutinas() {
  const { data, error } = await db.from('rutinas_control').select(`
    *, responsable:users!responsable_id(nombre, grado)
  `).eq('activa', true).order('criticidad');
  if (error) throw error;
  return data || [];
}

async function actualizarRutina(id, userId, observacion = '') {
  const ahora = new Date();
  const { data: rutina } = await db.from('rutinas_control').select('frecuencia').eq('id', id).single();
  let proxima = new Date(ahora);
  if (rutina.frecuencia === 'diaria')   proxima.setDate(proxima.getDate() + 1);
  if (rutina.frecuencia === 'semanal')  proxima.setDate(proxima.getDate() + 7);
  if (rutina.frecuencia === 'mensual')  proxima.setMonth(proxima.getMonth() + 1);

  await db.from('rutinas_control').update({
    ultima_actualizacion: ahora.toISOString(),
    actualizado_por: userId,
    proxima_revision: proxima.toISOString(),
    estado: 'vigente'
  }).eq('id', id);
  await registrarMovimiento(userId, 'rutina', id, 'actualizada', observacion || 'Rutina actualizada');
}

async function verificarRutinasvencidas() {
  const ahora = new Date().toISOString();
  await db.from('rutinas_control')
    .update({ estado: 'atrasada' })
    .lt('proxima_revision', ahora)
    .eq('activa', true)
    .neq('estado', 'atrasada');
}

// ─── FORMATOS ────────────────────────────────────
async function getFormatosPorTarea(tareaId) {
  const { data, error } = await db.from('formatos_oficiales')
    .select(`*, subido_por:users!subido_por(nombre)`)
    .eq('tarea_id', tareaId)
    .order('version', { ascending: false });
  if (error) throw error;
  return data || [];
}

async function subirFormato(tareaId, archivo, nombre, userId) {
  const ext = archivo.name.split('.').pop();
  const path = `formatos/${tareaId}/${Date.now()}.${ext}`;
  const { error: upErr } = await db.storage.from('sigo-archivos').upload(path, archivo);
  if (upErr) throw upErr;

  const { data: urlData } = db.storage.from('sigo-archivos').getPublicUrl(path);

  // Marcar anteriores como no vigentes
  await db.from('formatos_oficiales').update({ vigente: false }).eq('tarea_id', tareaId);

  // Obtener número de versión
  const { data: versiones } = await db.from('formatos_oficiales').select('version').eq('tarea_id', tareaId).order('version', { ascending: false }).limit(1);
  const nuevaVersion = versiones && versiones.length > 0 ? versiones[0].version + 1 : 1;

  const { data, error } = await db.from('formatos_oficiales').insert([{
    tarea_id: tareaId,
    nombre,
    archivo_url: urlData.publicUrl,
    tipo_archivo: ext,
    version: nuevaVersion,
    vigente: true,
    subido_por: userId
  }]).select().single();
  if (error) throw error;
  return data;
}

// ─── AVISOS ──────────────────────────────────────
async function getAvisos() {
  const hoy = new Date().toISOString().split('T')[0];
  const { data, error } = await db.from('informacion_permanente')
    .select(`*, publicado_por:users!publicado_por(nombre)`)
    .eq('activa', true)
    .gte('fecha_vigencia', hoy)
    .order('tipo')
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

async function crearAviso(aviso) {
  const { data, error } = await db.from('informacion_permanente').insert([aviso]).select().single();
  if (error) throw error;
  return data;
}

// ─── HISTORIAL ───────────────────────────────────
async function registrarMovimiento(userId, tipoEntidad, entidadId, accion, descripcion) {
  await db.from('historial_movimientos').insert([{
    usuario_id: userId,
    tipo_entidad: tipoEntidad,
    entidad_id: entidadId,
    accion,
    descripcion
  }]);
}

// ─── USUARIOS ────────────────────────────────────
async function getUsuarios() {
  const { data, error } = await db.from('users').select('*').eq('activo', true).order('nombre');
  if (error) throw error;
  return data || [];
}

// ─── MÉTRICAS ────────────────────────────────────
async function getMetricasHoy() {
  const hoy = new Date().toISOString().split('T')[0];
  const [tareas, ejecuciones, docs, rutinas] = await Promise.all([
    getTareasDelDia(hoy),
    getEjecucionesDelDia(hoy),
    getDocumentos(),
    getRutinas()
  ]);

  // Para tareas recurrentes: "finalizada" = tiene ejecución hoy
  // Para extraordinarias: mantiene su estado propio
  const tareasRecurrentes = tareas.filter(t => t.tipo !== 'extraordinaria');
  const tareasExtraordinarias = tareas.filter(t => t.tipo === 'extraordinaria');

  const ejIds = new Set(ejecuciones.map(e => e.tarea_id));
  const recurrentesRespondidas = tareasRecurrentes.filter(t => ejIds.has(t.id)).length;
  const extraordinariasFinalizadas = tareasExtraordinarias.filter(t => t.estado === 'finalizada').length;

  const tareasFinalizadas = recurrentesRespondidas + extraordinariasFinalizadas;
  const tareasTotal = tareas.length;
  const docsNuevos = docs.filter(d => d.estado === 'nuevo').length;
  const docsPendientes = docs.filter(d => ['nuevo','en_tramite','en_espera','parcial'].includes(d.estado)).length;
  const rutinasAtrasadas = rutinas.filter(r => r.estado === 'atrasada').length;
  const pctTareas = tareasTotal > 0 ? Math.round((tareasFinalizadas / tareasTotal) * 100) : 100;
  const pctRutinas = rutinas.length > 0 ? Math.round(((rutinas.length - rutinasAtrasadas) / rutinas.length) * 100) : 100;
  const ico = Math.round((pctTareas + pctRutinas) / 2);

  return { tareasFinalizadas, tareasTotal, docsNuevos, docsPendientes, rutinasAtrasadas, pctTareas, pctRutinas, ico };
}

// ─── HELPERS ─────────────────────────────────────
function formatFecha(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('es-CL', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

function formatFechaHora(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('es-CL', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function tiempoRelativo(iso) {
  if (!iso) return '—';
  const diff = Date.now() - new Date(iso).getTime();
  const min = Math.floor(diff / 60000);
  if (min < 1) return 'hace un momento';
  if (min < 60) return `hace ${min} min`;
  const h = Math.floor(min / 60);
  if (h < 24) return `hace ${h}h`;
  const d = Math.floor(h / 24);
  return `hace ${d} día${d > 1 ? 's' : ''}`;
}

function diasHasta(iso) {
  if (!iso) return null;
  const diff = new Date(iso).getTime() - Date.now();
  return Math.ceil(diff / 86400000);
}

function badgeEstadoTarea(estado) {
  const map = {
    pendiente:   ['badge-pendiente','⏳ Pendiente'],
    asignada:    ['badge-asignada','📌 Asignada'],
    en_ejecucion:['badge-ejecucion','🔄 En ejecución'],
    en_revision: ['badge-info','🔵 En revisión'],
    finalizada:  ['badge-finalizada','✅ Finalizada'],
    archivada:   ['badge-archivada','⚫ Archivada'],
  };
  const [cls, txt] = map[estado] || ['badge-archivada', estado];
  return `<span class="badge ${cls}">${txt}</span>`;
}

function badgeEstadoDoc(estado) {
  const map = {
    nuevo:      ['badge-nuevo','🟡 Nuevo'],
    en_tramite: ['badge-tramite','🟠 En Trámite'],
    en_espera:  ['badge-espera','⏳ En Espera'],
    parcial:    ['badge-asignada','🔄 Parcial'],
    listo:      ['badge-listo','🔵 Listo'],
    respondido: ['badge-finalizada','✅ Respondido'],
    archivado:  ['badge-archivada','⚫ Archivado'],
  };
  const [cls, txt] = map[estado] || ['badge-archivada', estado];
  return `<span class="badge ${cls}">${txt}</span>`;
}

function badgePrioridad(p) {
  const map = {
    critica:    ['badge-critica','🔴 Crítica'],
    alta:       ['badge-alta','🟠 Alta'],
    normal:     ['badge-normal','🟢 Normal'],
    informativa:['badge-archivada','🔵 Informativa'],
  };
  const [cls, txt] = map[p] || ['badge-archivada', p];
  return `<span class="badge ${cls}">${txt}</span>`;
}

function showToast(msg, tipo = 'success') {
  const t = document.createElement('div');
  t.className = `alert alert-${tipo}`;
  t.style.cssText = 'position:fixed;top:20px;right:20px;z-index:9999;min-width:280px;box-shadow:0 4px 20px rgba(0,0,0,0.2);animation:slideIn 0.3s ease';
  t.innerHTML = `<span>${msg}</span>`;
  document.body.appendChild(t);
  setTimeout(() => t.remove(), 3500);
}

function openModal(id) {
  document.getElementById(id)?.classList.add('active');
}

function closeModal(id) {
  document.getElementById(id)?.classList.remove('active');
}

// Cerrar modal al hacer click fuera
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-overlay')) {
    e.target.classList.remove('active');
  }
});

// ─── GUARD DE AUTENTICACIÓN ────────────────────────
async function authGuard() {
  const user = await getUser();
  if (!user && !window.location.pathname.includes('login.html')) {
    window.location.href = 'login.html';
    return null;
  }
  return user;
}

// ─── SIDEBAR MOBILE ────────────────────────────────
function toggleSidebar() {
  document.querySelector('.sidebar')?.classList.toggle('open');
  document.getElementById('sidebar-overlay')?.classList.toggle('active');
}

// ─── GESTIONES ─────────────────────────────────────

async function getGestiones(soloActivas = true) {
  let q = db.from('gestiones').select(`
    *,
    iniciada_por:users!iniciada_por(nombre, grado),
    hitos:hitos_gestion(*)
  `);
  if (soloActivas) {
    q = q.in('estado', ['abierta', 'en_curso', 'accion_requerida']);
  } else {
    q = q.in('estado', ['resuelta', 'cerrada']);
  }
  const { data, error } = await q.order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

async function getGestion(id) {
  const { data, error } = await db.from('gestiones').select(`
    *,
    iniciada_por:users!iniciada_por(nombre, grado),
    hitos:hitos_gestion(
      *,
      responsable:users!responsable_id(nombre, grado)
    )
  `).eq('id', id).single();
  if (error) throw error;
  return data;
}

async function crearGestion(gestion) {
  const { data, error } = await db.from('gestiones')
    .insert([gestion]).select().single();
  if (error) throw error;
  return data;
}

async function agregarHitoGestion(hito) {
  const { data, error } = await db.from('hitos_gestion')
    .insert([hito]).select().single();
  if (error) throw error;
  if (hito.fecha && hito.estado === 'pendiente') {
    await actualizarEstadoGestion(hito.gestion_id);
  }
  return data;
}

async function completarHitoGestion(hitoId, userId, observacion = '') {
  await db.from('hitos_gestion').update({
    estado: 'completado',
    completado_por: userId,
    completado_en: new Date().toISOString(),
    observacion: observacion || undefined
  }).eq('id', hitoId);
  const { data: hito } = await db.from('hitos_gestion')
    .select('gestion_id').eq('id', hitoId).single();
  if (hito) await actualizarEstadoGestion(hito.gestion_id);
}

async function actualizarEstadoGestion(gestionId) {
  const { data: hitos } = await db.from('hitos_gestion')
    .select('estado, fecha').eq('gestion_id', gestionId);
  if (!hitos || !hitos.length) return;
  const hoy = new Date().toISOString().split('T')[0];
  const todosCompletados = hitos.every(h => h.estado === 'completado');
  const hayVencidos = hitos.some(h =>
    h.estado === 'pendiente' && h.fecha && h.fecha < hoy
  );
  let nuevoEstado = 'abierta';
  if (todosCompletados) nuevoEstado = 'resuelta';
  else if (hayVencidos) nuevoEstado = 'accion_requerida';
  else if (hitos.some(h => h.estado === 'pendiente')) nuevoEstado = 'en_curso';
  await db.from('gestiones').update({
    estado: nuevoEstado,
    updated_at: new Date().toISOString()
  }).eq('id', gestionId);
}

async function cerrarGestion(gestionId, userId, notaCierre) {
  await db.from('gestiones').update({
    estado: 'cerrada',
    nota_cierre: notaCierre,
    cerrada_por: userId,
    cerrada_en: new Date().toISOString()
  }).eq('id', gestionId);
}

async function getHitosDelDia(fecha) {
  const { data, error } = await db.from('hitos_gestion').select(`
    *,
    gestion:gestiones!gestion_id(nombre, estado),
    responsable:users!responsable_id(nombre)
  `)
  .eq('fecha', fecha)
  .eq('estado', 'pendiente');
  if (error) return [];
  return data || [];
}

// ─── DATOS GLOBALES ────────────────────────────────
window.SIGO = {
  db, login, logout, getUser, getUserProfile,
  getTareas, getTareasDelDia, crearTarea, actualizarTarea, actualizarEstadoTarea, archivarTarea,
  getEjecucionesDelDia, getEjecucionesPorTarea, registrarEjecucion, eliminarEjecucion,
  // Sistema de Deudas
  getDeudasPendientes, getDeudasResueltas, resolverDeuda,
  generarDeudasPendientes, forzarRegeneracionDeudas, tareaTocabaEnFecha,
  getDocumentos, getDocumento, crearDocumento, tomarDocumento, actualizarEstadoDocumento, verificarConsolidacion,
  getRutinas, actualizarRutina, verificarRutinasvencidas,
  getFormatosPorTarea, subirFormato,
  getAvisos, crearAviso,
  getUsuarios, getMetricasHoy,
  formatFecha, formatFechaHora, tiempoRelativo, diasHasta,
  badgeEstadoTarea, badgeEstadoDoc, badgePrioridad,
  showToast, openModal, closeModal, authGuard, toggleSidebar,
  getGestiones, getGestion, crearGestion,
  agregarHitoGestion, completarHitoGestion, cerrarGestion, getHitosDelDia
};
