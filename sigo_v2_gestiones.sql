-- ═══════════════════════════════════════════════════════
-- SIGO v2.0 — SQL para módulo de Gestiones
-- Ejecutar en Supabase SQL Editor
-- ═══════════════════════════════════════════════════════

-- Tabla principal de Gestiones
CREATE TABLE IF NOT EXISTS gestiones (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  objetivo TEXT,
  area TEXT DEFAULT 'Operaciones',
  prioridad TEXT DEFAULT 'normal' CHECK (prioridad IN ('normal','alta','critica')),
  estado TEXT DEFAULT 'abierta' CHECK (estado IN ('abierta','en_curso','accion_requerida','resuelta','cerrada')),
  iniciada_por UUID REFERENCES users(id),
  fecha_limite DATE,
  nota_cierre TEXT,
  cerrada_por UUID REFERENCES users(id),
  cerrada_en TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de hitos por gestión
CREATE TABLE IF NOT EXISTS hitos_gestion (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  gestion_id UUID REFERENCES gestiones(id) ON DELETE CASCADE,
  descripcion TEXT NOT NULL,
  tipo TEXT DEFAULT 'accion' CHECK (tipo IN ('accion','registro')),
  estado TEXT DEFAULT 'pendiente' CHECK (estado IN ('pendiente','completado','cancelado')),
  responsable_id UUID REFERENCES users(id),
  fecha DATE,
  observacion TEXT,
  completado_por UUID REFERENCES users(id),
  completado_en TIMESTAMPTZ,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_gestiones_estado ON gestiones(estado);
CREATE INDEX IF NOT EXISTS idx_hitos_gestion_id ON hitos_gestion(gestion_id);
CREATE INDEX IF NOT EXISTS idx_hitos_fecha ON hitos_gestion(fecha);
CREATE INDEX IF NOT EXISTS idx_hitos_estado ON hitos_gestion(estado);

-- RLS (Row Level Security) — mismo patrón que las demás tablas
ALTER TABLE gestiones ENABLE ROW LEVEL SECURITY;
ALTER TABLE hitos_gestion ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Autenticados pueden leer gestiones"
  ON gestiones FOR SELECT TO authenticated USING (true);

CREATE POLICY "Autenticados pueden insertar gestiones"
  ON gestiones FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Autenticados pueden actualizar gestiones"
  ON gestiones FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Autenticados pueden leer hitos"
  ON hitos_gestion FOR SELECT TO authenticated USING (true);

CREATE POLICY "Autenticados pueden insertar hitos"
  ON hitos_gestion FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Autenticados pueden actualizar hitos"
  ON hitos_gestion FOR UPDATE TO authenticated USING (true);
