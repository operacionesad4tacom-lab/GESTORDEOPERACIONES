-- ═══════════════════════════════════════════════════════════════
-- SIGO — Sistema Integral de Gestión Operacional
-- Script SQL completo para Supabase (PostgreSQL)
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ─── EXTENSIONES ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── TABLA: users ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          UUID PRIMARY KEY,  -- Mismo UUID de Supabase Auth
  nombre      TEXT NOT NULL,
  grado       TEXT,
  rol         TEXT DEFAULT 'USUARIO' CHECK (rol IN ('ADMIN','OPERACIONES','USUARIO')),
  area        TEXT,
  activo      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── TABLA: documentos ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS documentos (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ncu                  TEXT NOT NULL,
  tipo                 TEXT DEFAULT 'entrante' CHECK (tipo IN ('entrante','interno','respuesta')),
  materia              TEXT NOT NULL,
  remitente            TEXT,
  destinatario         TEXT,
  fecha_recepcion      TIMESTAMPTZ DEFAULT NOW(),
  fecha_limite         TIMESTAMPTZ,
  estado               TEXT DEFAULT 'nuevo' CHECK (estado IN ('nuevo','en_tramite','en_espera','parcial','listo','respondido','archivado')),
  documento_padre_id   UUID REFERENCES documentos(id) ON DELETE SET NULL,
  asignado_a           UUID REFERENCES users(id) ON DELETE SET NULL,
  creado_por           UUID REFERENCES users(id) ON DELETE SET NULL,
  prioridad            TEXT DEFAULT 'normal' CHECK (prioridad IN ('critica','alta','normal')),
  visto_por            UUID REFERENCES users(id) ON DELETE SET NULL,
  fecha_lectura        TIMESTAMPTZ,
  observaciones        TEXT,
  activa               BOOLEAN DEFAULT TRUE,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para búsquedas por NCU
CREATE INDEX IF NOT EXISTS idx_documentos_ncu ON documentos(ncu);
CREATE INDEX IF NOT EXISTS idx_documentos_padre ON documentos(documento_padre_id);
CREATE INDEX IF NOT EXISTS idx_documentos_estado ON documentos(estado);

-- ─── TABLA: tareas ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tareas (
  id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titulo                    TEXT NOT NULL,
  descripcion               TEXT,
  tipo                      TEXT DEFAULT 'diaria' CHECK (tipo IN ('diaria','semanal','mensual','quincenal','extraordinaria')),
  prioridad                 TEXT DEFAULT 'normal' CHECK (prioridad IN ('critica','alta','normal','informativa')),
  dia_semana                INTEGER CHECK (dia_semana BETWEEN 1 AND 7),  -- 1=Lun, 7=Dom
  dia_mes                   INTEGER CHECK (dia_mes BETWEEN 1 AND 31),
  fecha_programada          DATE,                                          -- Solo para extraordinarias
  hora_limite               TIME,
  hora_limite_interna       TIME,
  responsable_id            UUID REFERENCES users(id) ON DELETE SET NULL,
  responsable_secundario_id UUID REFERENCES users(id) ON DELETE SET NULL,
  estado                    TEXT DEFAULT 'pendiente' CHECK (estado IN ('pendiente','asignada','en_ejecucion','en_revision','finalizada','archivada')),
  ultima_realizacion        TIMESTAMPTZ,
  area                      TEXT,
  documento_id              UUID REFERENCES documentos(id) ON DELETE SET NULL,
  activa                    BOOLEAN DEFAULT TRUE,
  created_at                TIMESTAMPTZ DEFAULT NOW(),
  updated_at                TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tareas_tipo ON tareas(tipo);
CREATE INDEX IF NOT EXISTS idx_tareas_estado ON tareas(estado);
CREATE INDEX IF NOT EXISTS idx_tareas_responsable ON tareas(responsable_id);

-- ─── TABLA: rutinas_control ──────────────────────────────────
CREATE TABLE IF NOT EXISTS rutinas_control (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre               TEXT NOT NULL,
  descripcion          TEXT,
  area                 TEXT,
  frecuencia           TEXT DEFAULT 'diaria' CHECK (frecuencia IN ('diaria','semanal','mensual')),
  criticidad           TEXT DEFAULT 'normal' CHECK (criticidad IN ('critica','alta','normal')),
  responsable_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  ultima_actualizacion TIMESTAMPTZ DEFAULT NOW(),
  actualizado_por      UUID REFERENCES users(id) ON DELETE SET NULL,
  proxima_revision     TIMESTAMPTZ,
  estado               TEXT DEFAULT 'vigente' CHECK (estado IN ('vigente','proxima','atrasada')),
  activa               BOOLEAN DEFAULT TRUE,
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ─── TABLA: formatos_oficiales ───────────────────────────────
CREATE TABLE IF NOT EXISTS formatos_oficiales (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tarea_id     UUID REFERENCES tareas(id) ON DELETE CASCADE,
  nombre       TEXT NOT NULL,
  archivo_url  TEXT NOT NULL,
  tipo_archivo TEXT,   -- xlsx, docx, pptx, pdf
  version      INTEGER DEFAULT 1,
  vigente      BOOLEAN DEFAULT TRUE,
  subido_por   UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_formatos_tarea ON formatos_oficiales(tarea_id);

-- ─── TABLA: informacion_permanente ───────────────────────────
CREATE TABLE IF NOT EXISTS informacion_permanente (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titulo         TEXT NOT NULL,
  contenido      TEXT NOT NULL,
  tipo           TEXT DEFAULT 'informativa' CHECK (tipo IN ('urgente','informativa','recordatorio')),
  area           TEXT DEFAULT 'todos',
  fecha_vigencia DATE NOT NULL,
  publicado_por  UUID REFERENCES users(id) ON DELETE SET NULL,
  activa         BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ─── TABLA: historial_movimientos ────────────────────────────
CREATE TABLE IF NOT EXISTS historial_movimientos (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  tipo_entidad  TEXT,   -- tarea, documento, rutina, informacion
  entidad_id    UUID,
  accion        TEXT,
  descripcion   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_historial_entidad ON historial_movimientos(entidad_id);
CREATE INDEX IF NOT EXISTS idx_historial_usuario ON historial_movimientos(usuario_id);

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES Y TRIGGERS
-- ═══════════════════════════════════════════════════════════════

-- Auto-actualizar updated_at en documentos y tareas
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_documentos_updated_at
  BEFORE UPDATE ON documentos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tareas_updated_at
  BEFORE UPDATE ON tareas
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Trigger: verificar consolidación automática del DOE padre
CREATE OR REPLACE FUNCTION verificar_consolidacion_padre()
RETURNS TRIGGER AS $$
DECLARE
  padre_id UUID;
  total_hijos INT;
  hijos_respondidos INT;
BEGIN
  padre_id := NEW.documento_padre_id;
  IF padre_id IS NULL THEN RETURN NEW; END IF;

  SELECT COUNT(*) INTO total_hijos
    FROM documentos WHERE documento_padre_id = padre_id AND activa = TRUE;

  SELECT COUNT(*) INTO hijos_respondidos
    FROM documentos WHERE documento_padre_id = padre_id AND estado = 'respondido' AND activa = TRUE;

  IF total_hijos > 0 AND total_hijos = hijos_respondidos THEN
    UPDATE documentos SET estado = 'listo', updated_at = NOW()
      WHERE id = padre_id AND estado NOT IN ('respondido','archivado');
  ELSIF hijos_respondidos > 0 THEN
    UPDATE documentos SET estado = 'parcial', updated_at = NOW()
      WHERE id = padre_id AND estado NOT IN ('listo','respondido','archivado');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_consolidacion_doe
  AFTER UPDATE OF estado ON documentos
  FOR EACH ROW
  WHEN (NEW.documento_padre_id IS NOT NULL)
  EXECUTE FUNCTION verificar_consolidacion_padre();

-- Función: marcar rutinas vencidas (ejecutar periódicamente)
CREATE OR REPLACE FUNCTION marcar_rutinas_vencidas()
RETURNS void AS $$
BEGIN
  UPDATE rutinas_control
    SET estado = 'atrasada'
    WHERE proxima_revision < NOW()
      AND activa = TRUE
      AND estado != 'atrasada';

  UPDATE rutinas_control
    SET estado = 'proxima'
    WHERE proxima_revision BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
      AND activa = TRUE
      AND estado = 'vigente';
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE users                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos             ENABLE ROW LEVEL SECURITY;
ALTER TABLE tareas                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE rutinas_control        ENABLE ROW LEVEL SECURITY;
ALTER TABLE formatos_oficiales     ENABLE ROW LEVEL SECURITY;
ALTER TABLE informacion_permanente ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_movimientos  ENABLE ROW LEVEL SECURITY;

-- Política básica: usuarios autenticados pueden leer todo
-- (puedes refinar según necesidad)
CREATE POLICY "Usuarios autenticados leen todo" ON users
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados leen documentos" ON documentos
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados insertan documentos" ON documentos
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Usuarios autenticados actualizan documentos" ON documentos
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados leen tareas" ON tareas
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados insertan tareas" ON tareas
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Usuarios autenticados actualizan tareas" ON tareas
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados leen rutinas" ON rutinas_control
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados insertan rutinas" ON rutinas_control
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Usuarios autenticados actualizan rutinas" ON rutinas_control
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados leen formatos" ON formatos_oficiales
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados insertan formatos" ON formatos_oficiales
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Usuarios autenticados actualizan formatos" ON formatos_oficiales
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados leen avisos" ON informacion_permanente
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados insertan avisos" ON informacion_permanente
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Usuarios autenticados actualizan avisos" ON informacion_permanente
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados leen historial" ON historial_movimientos
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados insertan historial" ON historial_movimientos
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Usuarios insertan su perfil" ON users
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Usuarios actualizan su perfil" ON users
  FOR UPDATE TO authenticated USING (auth.uid() = id);

-- ═══════════════════════════════════════════════════════════════
-- DATOS DE EJEMPLO (OPCIONALES - borrar en producción)
-- ═══════════════════════════════════════════════════════════════

/*
-- Rutinas de ejemplo (insertar después de crear el primer usuario)
INSERT INTO rutinas_control (nombre, descripcion, area, frecuencia, criticidad, proxima_revision, estado) VALUES
  ('Panel Comando y Control', 'Verificar y actualizar el panel de comando y control', 'Operaciones', 'diaria', 'critica', NOW() + INTERVAL '1 day', 'vigente'),
  ('Estado de Fuerza', 'Actualizar estado de fuerza diario', 'Operaciones', 'diaria', 'critica', NOW() + INTERVAL '1 day', 'vigente'),
  ('Estadísticas Semanales', 'Consolidar estadísticas de la semana', 'Operaciones', 'semanal', 'alta', NOW() + INTERVAL '7 days', 'vigente'),
  ('Mapa de Contingencia', 'Revisar y actualizar mapa de contingencia', 'Operaciones', 'semanal', 'alta', NOW() + INTERVAL '7 days', 'vigente'),
  ('Informe Mensual', 'Preparar informe mensual de gestión', 'Operaciones', 'mensual', 'normal', NOW() + INTERVAL '30 days', 'vigente');
*/
