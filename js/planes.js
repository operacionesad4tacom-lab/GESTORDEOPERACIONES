// ═══════════════════════════════════════════════
// SIGO — Control de Planes Operativos
// Lógica compartida del módulo (requiere js/supabase.js)
// Fechas: dd.mm.aaaa · horas 24 h · zona America/Santiago
// ═══════════════════════════════════════════════

(function () {
  const db = SIGO.db;
  const TZ = 'America/Santiago';

  // ─── Catálogos ──────────────────────────────────
  const TIPOS = {
    plan_operativo:     'Plan Operativo',
    plan_abreviado:     'Plan Abreviado',
    orden_doe:          'Orden por DOE',
    emergencia:         'Emergencia / Contingencia',
    mesa_coordinacion:  'Mesa de coordinación',
    evento_preparacion: 'Evento en preparación',
  };
  const EMISORES = {
    direccion_nacional:       'Dirección Nacional',
    zona:                     'Zona',
    prefectura:               'Prefectura',
    subprefectura_fronteriza: 'Subprefectura Fronteriza',
    comisaria:                'Comisaría',
    seremi:                   'Seremi',
    otro:                     'Otro',
  };
  const PRIORIDADES = { normal: 'Normal', importante: 'Importante', critica: 'Crítica' };
  const ESTADOS = {
    por_revisar:     ['Por revisar',        'badge-nuevo'],
    proximo:         ['Próximo',            'badge-asignada'],
    en_curso:        ['En curso',           'badge-ejecucion'],
    pendiente_labor: ['Pendiente de labor', 'badge-critica'],
    finalizado:      ['Finalizado',         'badge-finalizada'],
    cerrado:         ['Cerrado',            'badge-archivada'],
  };
  const GRADOS = [['crl','Crl'],['tcrl','Tcrl'],['may','May'],['cap','Cap'],['tte','Tte/Of.'],['pns','PNS'],['pni','PNI']];
  const MEDIOS = [['fz','FZ'],['rp','RP'],['ab','AB'],['ac','AC'],['m','M'],['tt','T/T'],['tl','T/L'],['rm','R/M'],['ap','AP'],['can','CAN']];
  const PLAZO_TIPOS = {
    acuse_recibo: 'Acuse de recibo', labor: 'Labor', evaluacion: 'Evaluación',
    informe_semanal: 'Informe semanal', remision_plan: 'Remisión de plan', otro: 'Otro',
  };
  const INSTITUCIONES = ['PDI','Ejército','Armada','SAG','SII','Aduanas','SUNAT','MTT','SENAPRED','Otra'];
  const NE = '<span class="po-ne">No especificado</span>';

  // ─── Utilidades ─────────────────────────────────
  function esc(v) {
    return String(v ?? '').replace(/[&<>"']/g, c =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }
  // Valor o "No especificado"
  function val(v) {
    return v === null || v === undefined || v === '' ? NE : esc(v);
  }

  // ─── Fechas en America/Santiago ─────────────────
  const fmtPartes = new Intl.DateTimeFormat('en-CA', {
    timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', hour12: false,
  });
  function partes(d) {
    const p = {};
    fmtPartes.formatToParts(d).forEach(x => { p[x.type] = x.value; });
    if (p.hour === '24') p.hour = '00';
    return p;
  }
  function offsetMin(d) {
    const p = partes(d);
    const comoUTC = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute);
    return Math.round((comoUTC - Math.floor(d.getTime() / 60000) * 60000) / 60000);
  }
  // ISO (UTC) → "dd.mm.aaaa"
  function fFecha(iso) {
    if (!iso) return '';
    if (/^\d{4}-\d{2}-\d{2}$/.test(iso)) { const [y, m, d] = iso.split('-'); return `${d}.${m}.${y}`; }
    const p = partes(new Date(iso));
    return `${p.day}.${p.month}.${p.year}`;
  }
  function fHora(iso) {
    if (!iso) return '';
    const p = partes(new Date(iso));
    return `${p.hour}:${p.minute}`;
  }
  function fFechaHora(iso) { return iso ? `${fFecha(iso)} ${fHora(iso)}` : ''; }
  // Fecha local (aaaa-mm-dd) en Santiago de un instante
  function diaISO(iso) {
    const p = partes(iso instanceof Date ? iso : new Date(iso));
    return `${p.year}-${p.month}-${p.day}`;
  }
  // ISO → valor para <input type="datetime-local">
  function aInput(iso) {
    if (!iso) return '';
    const p = partes(new Date(iso));
    return `${p.year}-${p.month}-${p.day}T${p.hour}:${p.minute}`;
  }
  // "aaaa-mm-ddTHH:MM" (hora de Santiago) → ISO UTC
  function deInput(s) {
    if (!s) return null;
    const [d, t = '00:00'] = s.split('T');
    const [y, m, dia] = d.split('-').map(Number);
    const [h, mi] = t.split(':').map(Number);
    const supuesto = Date.UTC(y, m - 1, dia, h, mi);
    let ts = supuesto - offsetMin(new Date(supuesto)) * 60000;
    const off2 = offsetMin(new Date(ts));
    ts = supuesto - off2 * 60000;
    return new Date(ts).toISOString();
  }
  // "dd.mm.aaaa" → "aaaa-mm-dd" (null si no es válida)
  function parseFechaCL(s) {
    const m = String(s).trim().match(/^(\d{1,2})[.\/-](\d{1,2})[.\/-](\d{4})$/);
    if (!m) return null;
    const d = m[1].padStart(2, '0'), mo = m[2].padStart(2, '0');
    const iso = `${m[3]}-${mo}-${d}`;
    const test = new Date(`${iso}T12:00:00Z`);
    return test.getUTCDate() === +m[1] && test.getUTCMonth() + 1 === +m[2] ? iso : null;
  }
  function sumarDias(isoDia, n) {
    const t = new Date(`${isoDia}T12:00:00Z`);
    t.setUTCDate(t.getUTCDate() + n);
    return t.toISOString().slice(0, 10);
  }
  function diaSemana(isoDia) { // 1=Lun … 7=Dom
    const g = new Date(`${isoDia}T12:00:00Z`).getUTCDay();
    return g === 0 ? 7 : g;
  }

  // ─── Estado calculado ───────────────────────────
  function estadoPlan(plan, ahora = new Date()) {
    if (plan.revision === 'por_revisar') return 'por_revisar';
    if (plan.cerrado) return 'cerrado';
    const t = ahora.getTime();
    const sv = plan.servicios || [];
    if (sv.length) {
      if (sv.some(s => +new Date(s.inicio) <= t && t <= +new Date(s.termino))) return 'en_curso';
      if (sv.some(s => +new Date(s.inicio) > t)) return 'proximo';
      if (plan.hasta_nueva_orden) return 'en_curso';
    } else {
      const ini = plan.inicio ? +new Date(plan.inicio) : null;
      const ter = plan.termino ? +new Date(plan.termino) : null;
      if (plan.hasta_nueva_orden) return ini === null || ini <= t ? 'en_curso' : 'proximo';
      if (ini === null && ter === null) return 'proximo';
      if (ini !== null && t < ini) return 'proximo';
      if (ter === null || t <= ter) return 'en_curso';
    }
    const laborPendiente = (plan.plazos || []).some(p => p.tipo === 'labor' && p.estado === 'pendiente');
    return laborPendiente ? 'pendiente_labor' : 'finalizado';
  }
  function badgeEstado(estado) {
    const [txt, cls] = ESTADOS[estado] || [estado, 'badge-archivada'];
    return `<span class="badge ${cls}">${txt}</span>`;
  }
  function badgePrioridad(p) {
    const cls = { normal: 'badge-normal', importante: 'badge-alta', critica: 'badge-critica' }[p] || 'badge-normal';
    return `<span class="badge ${cls}">${PRIORIDADES[p] || esc(p)}</span>`;
  }

  // Semáforo de plazos: vencido · vence hoy · vence en 48 h · a tiempo
  function semaforoPlazo(p, ahora = new Date()) {
    if (p.estado === 'cumplido') return { clave: 'cumplido', texto: 'Cumplido', cls: 'badge-finalizada' };
    if (!p.vence) return { clave: 'sin_fecha', texto: 'Sin fecha', cls: 'badge-archivada' };
    const diff = new Date(p.vence) - ahora;
    if (diff < 0) return { clave: 'vencido', texto: 'Vencido', cls: 'badge-critica' };
    if (diaISO(p.vence) === diaISO(ahora)) return { clave: 'hoy', texto: 'Vence hoy', cls: 'badge-alta' };
    if (diff <= 48 * 3600000) return { clave: '48h', texto: 'Vence en 48 h', cls: 'badge-pendiente' };
    return { clave: 'a_tiempo', texto: 'A tiempo', cls: 'badge-normal' };
  }

  // Rango visible de un plan (desde sus servicios o sus fechas)
  function rangoPlan(plan) {
    const sv = plan.servicios || [];
    if (sv.length) {
      const ini = sv.reduce((a, s) => (!a || s.inicio < a ? s.inicio : a), null);
      const fin = sv.reduce((a, s) => (!a || s.termino > a ? s.termino : a), null);
      return { inicio: ini, termino: fin };
    }
    return { inicio: plan.inicio, termino: plan.termino };
  }
  function textoRango(plan) {
    if (plan.hasta_nueva_orden && !plan.inicio && !(plan.servicios || []).length) return 'Hasta nueva orden';
    const { inicio, termino } = rangoPlan(plan);
    if (!inicio && !termino) return 'Fechas no especificadas';
    const a = inicio ? fFecha(inicio) : '¿?';
    const b = termino ? fFecha(termino) : (plan.hasta_nueva_orden ? 'nueva orden' : '¿?');
    return a === b ? a : `${a} – ${b}`;
  }

  // ─── Recursos ───────────────────────────────────
  function sumaRecursos(recursos) {
    const r = { personal: 0, especificado: false, medios: {} };
    (recursos || []).forEach(x => {
      GRADOS.forEach(([k]) => { if (x[k] != null) { r.personal += x[k]; r.especificado = true; } });
      MEDIOS.forEach(([k]) => { if (x[k] != null) r.medios[k] = (r.medios[k] || 0) + x[k]; });
    });
    return r;
  }
  function textoMedios(medios) {
    const t = MEDIOS.filter(([k]) => medios[k]).map(([k, l]) => `${medios[k]} ${l}`);
    return t.length ? t.join(' · ') : '';
  }

  // ─── Rol del usuario en el módulo (solo para la interfaz; la seguridad real es RLS) ─
  function rolModulo(profile) {
    if (!profile) return 'consulta';
    if (profile.planes_rol) return profile.planes_rol;
    return ['ADMIN', 'OPERACIONES'].includes(profile.rol) ? 'admin_operaciones' : 'consulta';
  }

  // ─── Acceso a datos ─────────────────────────────
  async function listarPlanes() {
    const { data, error } = await db.from('po_planes').select(`
      *,
      servicios:po_servicios(inicio, termino, faccion_id),
      plazos:po_plazos(tipo, estado, vence),
      ncu:po_ncu(ncu),
      contradicciones:po_contradicciones(resuelta),
      recursos:po_recursos(crl, tcrl, may, cap, tte, pns, pni)
    `).order('inicio', { ascending: true, nullsFirst: false });
    if (error) throw error;
    return data || [];
  }

  async function obtenerPlan(id) {
    const { data, error } = await db.from('po_planes').select(`
      *,
      ncu:po_ncu(*),
      etapas:po_etapas(*),
      facciones:po_facciones(*, recursos:po_recursos(*)),
      servicios:po_servicios(*),
      plazos:po_plazos(*),
      contradicciones:po_contradicciones(*),
      indicadores:po_indicadores(*)
    `).eq('id', id).single();
    if (error) throw error;
    const porOrden = (a, b) => (a.orden ?? 0) - (b.orden ?? 0);
    data.etapas.sort(porOrden);
    data.facciones.sort(porOrden);
    data.indicadores.sort(porOrden);
    data.servicios.sort((a, b) => a.inicio.localeCompare(b.inicio));
    data.plazos.sort((a, b) => (a.vence || '9999').localeCompare(b.vence || '9999'));
    // Los NCU son correlativos: ordenar por número reproduce el orden de la traza DOE
    data.ncu.sort((a, b) => a.ncu.padStart(12, '0').localeCompare(b.ncu.padStart(12, '0')));
    return data;
  }

  let cacheUnidades = null;
  async function unidades() {
    if (cacheUnidades) return cacheUnidades;
    const { data, error } = await db.from('po_unidades').select('*').eq('activa', true).order('orden');
    if (error) throw error;
    cacheUnidades = data || [];
    return cacheUnidades;
  }

  async function guardar(tabla, fila) {
    const { id, ...resto } = fila;
    const q = id
      ? db.from(tabla).update(resto).eq('id', id)
      : db.from(tabla).insert([resto]);
    const { data, error } = await q.select().single();
    if (error) throw error;
    return data;
  }

  async function guardarVarios(tabla, filas) {
    if (!filas.length) return [];
    const { data, error } = await db.from(tabla).insert(filas).select();
    if (error) throw error;
    return data;
  }

  async function borrar(tabla, id) {
    const { error } = await db.from(tabla).delete().eq('id', id);
    if (error) throw error;
  }

  // Planes existentes con el mismo NCU o el mismo número+emisor
  async function buscarDuplicados({ ncus = [], numero = null, emisor = null, excluirId = null }) {
    const encontrados = new Map();
    const limpios = ncus.filter(n => n != null).map(n => String(n).trim()).filter(Boolean);
    if (limpios.length) {
      const { data } = await db.from('po_ncu')
        .select('ncu, plan:po_planes(id, titulo, numero, es_plantilla)').in('ncu', limpios);
      (data || []).forEach(r => {
        if (r.plan && !r.plan.es_plantilla && r.plan.id !== excluirId)
          encontrados.set(r.plan.id, { ...r.plan, motivo: `NCU ${r.ncu} ya registrado` });
      });
    }
    if (numero) {
      let q = db.from('po_planes').select('id, titulo, numero').eq('numero', numero).eq('es_plantilla', false);
      q = emisor ? q.eq('emisor', emisor) : q.is('emisor', null);
      const { data } = await q;
      (data || []).forEach(p => {
        if (p.id !== excluirId && !encontrados.has(p.id))
          encontrados.set(p.id, { ...p, motivo: `Plan N°${p.numero} del mismo emisor ya existe` });
      });
    }
    return [...encontrados.values()];
  }

  // Copia profunda de un plan: como plantilla (sin fechas) o nuevo plan desde plantilla
  async function copiarPlan(id, { comoPlantilla, userId }) {
    const p = await obtenerPlan(id);
    const base = {
      tipo: p.tipo, numero: comoPlantilla ? p.numero : null, titulo: p.titulo,
      emisor: p.emisor, emisor_detalle: p.emisor_detalle, mision: p.mision,
      hasta_nueva_orden: p.hasta_nueva_orden, recurrencia: p.recurrencia,
      jefe_servicio: comoPlantilla ? p.jefe_servicio : null,
      supervisor: comoPlantilla ? p.supervisor : null,
      prioridad: p.prioridad, personal_total_declarado: p.personal_total_declarado,
      observaciones: p.observaciones,
      es_plantilla: !!comoPlantilla,
      revision: comoPlantilla ? 'confirmado' : 'por_revisar',
      plantilla_origen_id: comoPlantilla ? null : p.id,
      creado_por: userId,
    };
    if (comoPlantilla) base.titulo = `${p.titulo}`;
    const nuevo = await guardar('po_planes', base);

    const mapaEtapas = {};
    for (const e of p.etapas) {
      const ne = await guardar('po_etapas', {
        plan_id: nuevo.id, nombre: e.nombre, lugar: e.lugar, tactica: e.tactica, orden: e.orden,
      });
      mapaEtapas[e.id] = ne.id;
    }
    for (const f of p.facciones) {
      const nf = await guardar('po_facciones', {
        plan_id: nuevo.id, etapa_id: f.etapa_id ? mapaEtapas[f.etapa_id] : null,
        nombre: f.nombre, lugar: f.lugar, unidad_cargo_id: f.unidad_cargo_id,
        jefe_faccion: comoPlantilla ? f.jefe_faccion : null,
        apoyo_instituciones: f.apoyo_instituciones, apoyo_detalle: f.apoyo_detalle,
        observaciones: f.observaciones, orden: f.orden,
      });
      await guardarVarios('po_recursos', f.recursos.map(r => {
        const { id: _i, plan_id: _p, faccion_id: _f, total_personal: _t, ...resto } = r;
        return { ...resto, plan_id: nuevo.id, faccion_id: nf.id };
      }));
    }
    await guardarVarios('po_indicadores', p.indicadores.map(x => ({
      plan_id: nuevo.id, nombre: x.nombre, tipo: x.tipo, numerador: x.numerador,
      denominador: x.denominador, descripcion: x.descripcion, orden: x.orden,
    })));
    await guardarVarios('po_plazos', p.plazos.map(x => ({
      plan_id: nuevo.id, tipo: x.tipo, descripcion: x.descripcion, destinatario: x.destinatario,
      formato: x.formato, al_termino_servicio: x.al_termino_servicio,
    })));
    return nuevo;
  }

  // ─── Formulario genérico en modal ───────────────
  // campos: [{k, label, tipo:'text'|'textarea'|'select'|'date'|'datetime'|'number'|'check'|'multi'|'html', opciones, ancho:'full'|'half'|'third', ayuda}]
  function abrirFormulario({ titulo, campos, valores = {}, textoGuardar = 'Guardar', alGuardar, ancho = 620, intro = '' }) {
    let modal = document.getElementById('po-modal');
    if (!modal) {
      modal = document.createElement('div');
      modal.className = 'modal-overlay';
      modal.id = 'po-modal';
      document.body.appendChild(modal);
    }
    const control = c => {
      const v = valores[c.k];
      const id = `pof-${c.k}`;
      switch (c.tipo) {
        case 'textarea':
          return `<textarea id="${id}" class="form-control" rows="${c.filas || 3}" placeholder="${esc(c.placeholder || '')}">${esc(v ?? '')}</textarea>`;
        case 'select':
          return `<select id="${id}" class="form-control">
            ${c.vacio !== false ? `<option value="">${esc(c.vacio || '— No especificado —')}</option>` : ''}
            ${Object.entries(c.opciones).map(([k, l]) => `<option value="${esc(k)}" ${String(v ?? '') === String(k) ? 'selected' : ''}>${esc(l)}</option>`).join('')}
          </select>`;
        case 'date':
          return `<input id="${id}" type="date" class="form-control" value="${esc(v ?? '')}">`;
        case 'datetime':
          return `<input id="${id}" type="datetime-local" class="form-control" value="${esc(aInput(v))}">`;
        case 'time':
          return `<input id="${id}" type="time" class="form-control" value="${esc(v ?? '')}">`;
        case 'number':
          return `<input id="${id}" type="number" min="0" class="form-control" value="${v ?? ''}" placeholder="—">`;
        case 'check':
          return `<label class="po-check"><input id="${id}" type="checkbox" ${v ? 'checked' : ''}> ${esc(c.textoCheck || '')}</label>`;
        case 'multi':
          return `<div class="po-multi" id="${id}">${c.opciones.map(o =>
            `<label class="po-check"><input type="checkbox" value="${esc(o)}" ${(v || []).includes(o) ? 'checked' : ''}> ${esc(o)}</label>`).join('')}</div>`;
        case 'html':
          return c.html;
        default:
          return `<input id="${id}" type="text" class="form-control" value="${esc(v ?? '')}" placeholder="${esc(c.placeholder || '')}">`;
      }
    };
    modal.innerHTML = `
      <div class="modal" style="max-width:${ancho}px;">
        <div class="modal-header"><h3>${esc(titulo)}</h3>
          <button class="modal-close" type="button" data-cerrar>✕</button></div>
        <div class="modal-body">
          ${intro}
          <div class="po-form-grid">
            ${campos.map(c => `<div class="form-group po-w-${c.ancho || 'full'}">
              ${c.tipo === 'check' || c.tipo === 'html' ? '' : `<label for="pof-${c.k}">${esc(c.label)}</label>`}
              ${control(c)}
              ${c.ayuda ? `<div class="po-ayuda">${esc(c.ayuda)}</div>` : ''}
            </div>`).join('')}
          </div>
          <div class="alert alert-danger hidden" id="po-modal-error"></div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-outline" type="button" data-cerrar>Cancelar</button>
          <button class="btn btn-primary" type="button" id="po-modal-guardar">${esc(textoGuardar)}</button>
        </div>
      </div>`;
    modal.querySelectorAll('[data-cerrar]').forEach(b => b.onclick = () => modal.classList.remove('active'));
    modal.querySelector('#po-modal-guardar').onclick = async () => {
      const out = {};
      campos.forEach(c => {
        const el = document.getElementById(`pof-${c.k}`);
        if (!el || c.tipo === 'html') return;
        switch (c.tipo) {
          case 'check':    out[c.k] = el.checked; break;
          case 'number':   out[c.k] = el.value === '' ? null : Number(el.value); break;
          case 'datetime': out[c.k] = deInput(el.value); break;
          case 'multi':    out[c.k] = [...el.querySelectorAll('input:checked')].map(i => i.value); break;
          default:         out[c.k] = el.value.trim() === '' ? null : el.value.trim();
        }
      });
      const btn = modal.querySelector('#po-modal-guardar');
      const errEl = modal.querySelector('#po-modal-error');
      btn.disabled = true;
      errEl.classList.add('hidden');
      try {
        const r = await alGuardar(out);
        if (r !== false) modal.classList.remove('active');
      } catch (e) {
        errEl.textContent = e.message || String(e);
        errEl.classList.remove('hidden');
      } finally {
        btn.disabled = false;
      }
    };
    modal.classList.add('active');
    return modal;
  }

  // Diálogo de opciones: resuelve con la clave elegida o null
  function elegir({ titulo, mensaje, opciones }) {
    return new Promise(resolve => {
      let modal = document.getElementById('po-elegir');
      if (!modal) {
        modal = document.createElement('div');
        modal.className = 'modal-overlay';
        modal.id = 'po-elegir';
        document.body.appendChild(modal);
      }
      modal.innerHTML = `<div class="modal" style="max-width:520px;">
        <div class="modal-header"><h3>${esc(titulo)}</h3></div>
        <div class="modal-body">${mensaje}</div>
        <div class="modal-footer" style="flex-wrap:wrap;">
          ${opciones.map(o => `<button class="btn ${o.clase || 'btn-outline'}" data-k="${esc(o.k)}">${esc(o.texto)}</button>`).join('')}
        </div></div>`;
      modal.querySelectorAll('[data-k]').forEach(b => b.onclick = () => {
        modal.classList.remove('active');
        resolve(b.dataset.k === 'cancelar' ? null : b.dataset.k);
      });
      modal.classList.add('active');
    });
  }

  // Encabezado común (usuario en la barra lateral)
  async function iniciarPagina() {
    const user = await SIGO.authGuard();
    if (!user) return null;
    const profile = await SIGO.getUserProfile(user.id);
    if (profile) {
      document.getElementById('user-name').textContent = profile.nombre;
      document.getElementById('user-role').textContent = profile.grado || profile.rol || '';
      document.getElementById('user-avatar').textContent = profile.nombre?.charAt(0) || '?';
    }
    const rol = rolModulo(profile);
    document.body.dataset.rol = rol;
    return { user, profile, rol, esAdmin: rol === 'admin_operaciones' };
  }

  window.PO = {
    TZ, TIPOS, EMISORES, PRIORIDADES, ESTADOS, GRADOS, MEDIOS, PLAZO_TIPOS, INSTITUCIONES, NE,
    esc, val, fFecha, fHora, fFechaHora, diaISO, aInput, deInput, parseFechaCL, sumarDias, diaSemana,
    estadoPlan, badgeEstado, badgePrioridad, semaforoPlazo, rangoPlan, textoRango, sumaRecursos, textoMedios, rolModulo,
    listarPlanes, obtenerPlan, unidades, guardar, guardarVarios, borrar, buscarDuplicados, copiarPlan,
    abrirFormulario, elegir, iniciarPagina,
  };
})();
