// ═══════════════════════════════════════════════
// SIGO — Configuración Supabase
// ⚠️ REEMPLAZA estos valores con los tuyos de Supabase
// ═══════════════════════════════════════════════

const SUPABASE_URL = 'https://TU_PROYECTO.supabase.co';
const SUPABASE_KEY = 'TU_ANON_KEY_AQUI';

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

async function archivarTarea(id, userId) {
  await actualizarTarea(id, { activa: false, estado: 'archivada' });
  await registrarMovimiento(userId, 'tarea', id, 'archivada', 'Tarea archivada');
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
  const [tareas, docs, rutinas] = await Promise.all([
    getTareasDelDia(hoy),
    getDocumentos(),
    getRutinas()
  ]);

  const tareasFinalizadas = tareas.filter(t => t.estado === 'finalizada').length;
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

// ─── DATOS GLOBALES ────────────────────────────────
window.SIGO = {
  db, login, logout, getUser, getUserProfile,
  getTareas, getTareasDelDia, crearTarea, actualizarTarea, actualizarEstadoTarea, archivarTarea,
  getDocumentos, getDocumento, crearDocumento, tomarDocumento, actualizarEstadoDocumento, verificarConsolidacion,
  getRutinas, actualizarRutina, verificarRutinasvencidas,
  getFormatosPorTarea, subirFormato,
  getAvisos, crearAviso,
  getUsuarios, getMetricasHoy,
  formatFecha, formatFechaHora, tiempoRelativo, diasHasta,
  badgeEstadoTarea, badgeEstadoDoc, badgePrioridad,
  showToast, openModal, closeModal, authGuard
};
