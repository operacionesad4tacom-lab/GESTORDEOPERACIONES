# SIGO v2.0 — Sistema Integral de Gestión Operacional
## 4ª Comisaría — Carabineros de Chile
### Instrucciones de Implementación

---

## ¿QUÉ INCLUYE ESTE PAQUETE?

```
SIGO_v2/
├── index.html          ← Vista de Turno (NUEVO — reemplaza al Dashboard)
├── login.html          ← Sin cambios
├── tareas.html         ← Rediseño completo — Herramienta administrativa
├── calendario.html     ← Rediseño completo — Mapa de Carga Mensual
├── gestiones.html      ← NUEVO — Módulo de Gestiones de múltiples pasos
├── documentos.html     ← Corregido — modal reemplaza prompt() nativo
├── rutinas.html        ← Corregido — tabla simplificada a 6 columnas
├── avisos.html         ← Corregido — límite 10 + orden por fecha
├── formatos.html       ← Sin cambios
├── usuarios.html       ← Sin cambios
├── css/styles.css      ← Actualizado con estilos nuevos (sin eliminar existentes)
├── js/supabase.js      ← Actualizado con funciones de Gestiones
├── sigo_v2_gestiones.sql ← SQL para ejecutar en Supabase
└── assets/escudo.jpg  ← Sin cambios
```

---

## RESUMEN DE MEJORAS

### Cambios críticos
- **Vista de Turno** (`index.html`): Reemplaza el dashboard por una lista inteligente del día, con detección automática de tareas atrasadas, modal de registro sin `prompt()`, mini-calendario semanal y panel de aviso urgente.
- **Módulo Gestiones** (`gestiones.html`): Nuevo módulo para seguimiento de procesos multietapa con línea de tiempo, hitos, progreso y alertas.
- **Tareas** (`tareas.html`): Reorganizado en 3 pestañas (Activas, Extraordinarias, Archivo). Sin eliminación — solo archivado con motivo y referencia.
- **Calendario** (`calendario.html`): Muestra número total de cuentas por día con código de color por carga. Panel lateral detallado al seleccionar un día.

### Correcciones
- Todos los archivos HTML ahora tienen **botón hamburguesa** para navegación en mobile.
- `documentos.html`: Se elimina el `prompt()` nativo, reemplazado por modal con select.
- `rutinas.html`: Tabla reducida de 9 a 6 columnas.
- `avisos.html`: Orden por urgencia + fecha, límite de 10 con paginación.
- **Badges en sidebar**: Se ocultan automáticamente cuando el valor es 0.

---

## PASOS DE IMPLEMENTACIÓN

### PASO 1 — Ejecutar el SQL de Gestiones en Supabase

1. Ir a **Supabase → SQL Editor**
2. Pegar el contenido de `sigo_v2_gestiones.sql`
3. Presionar **Run (▶)**
4. Verificar que no hubo errores

> ⚠️ Este paso es obligatorio antes de usar el módulo Gestiones. Si no se ejecuta, el módulo de Gestiones no funcionará, pero el resto del sistema operará con normalidad.

### PASO 2 — Reemplazar los archivos del proyecto

Reemplazar TODOS los archivos de la carpeta actual del proyecto SIGO con los de esta entrega:

| Archivo | Acción |
|---------|--------|
| `index.html` | ✅ Reemplazar |
| `tareas.html` | ✅ Reemplazar |
| `calendario.html` | ✅ Reemplazar |
| `gestiones.html` | ✅ Agregar (nuevo) |
| `documentos.html` | ✅ Reemplazar |
| `rutinas.html` | ✅ Reemplazar |
| `avisos.html` | ✅ Reemplazar |
| `formatos.html` | ✅ Reemplazar |
| `usuarios.html` | ✅ Reemplazar |
| `css/styles.css` | ✅ Reemplazar |
| `js/supabase.js` | ✅ Reemplazar |
| `login.html` | ✅ Reemplazar |
| `assets/escudo.jpg` | ⬡ No incluido en este paquete — mantener el existente |

> ⚠️ No reemplazar `assets/escudo.jpg` — ese archivo no se incluye en este paquete.

### PASO 3 — Verificar credenciales

El archivo `js/supabase.js` ya contiene las credenciales del proyecto. Verificar que las líneas 6 y 7 tengan los valores correctos:

```javascript
const SUPABASE_URL = 'https://hkqyzfoxucusboloqitr.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### PASO 4 — Probar el sistema

1. Abrir `login.html` en el navegador
2. Ingresar con un usuario existente
3. Verificar que la Vista de Turno carga correctamente
4. Ir a Gestiones y crear la primera gestión
5. Verificar que el Calendario muestra números en las celdas

---

## NOVEDADES FUNCIONALES

### Vista de Turno (nueva página de inicio)
- Lista automática de cuentas del día ordenada por urgencia
- Detección de cuentas atrasadas de días anteriores (hasta 7 días)
- Registro con modal (sin `prompt()` del navegador)
- Mini-calendario de la semana con puntos verde/rojo
- Panel de próximas tareas del día siguiente
- Banda de alerta roja cuando hay avisos urgentes activos

### Módulo Gestiones (nuevo)
- Tarjetas por gestión con barra de progreso
- Línea de tiempo con hitos
- Hitos pendientes con botón de completar
- Estados automáticos: abierta → en_curso → acción_requerida → resuelta
- Los hitos con fecha aparecen en el Calendario
- Vista de Gestiones cerradas

### Calendario mejorado
- Número total de cuentas visible en cada celda
- Código de color por carga: blanco (1-4), verde (5-8), amarillo (9-12), naranja (13+)
- Panel lateral con detalle al seleccionar un día
- Resumen del mes en la cabecera
- Puntos de estado para días pasados

---

## PREGUNTAS FRECUENTES

**¿El sistema sigue funcionando con los datos existentes?**
Sí. Los cambios en `js/supabase.js` solo agregan funciones nuevas sin modificar las existentes. Los datos de tareas, documentos, rutinas y avisos permanecen intactos.

**¿Necesito volver a crear los usuarios?**
No. Los usuarios existentes funcionan exactamente igual.

**¿Qué pasa si no ejecuto el SQL de Gestiones?**
El sistema funciona normalmente en todos los módulos existentes. Solo el módulo `gestiones.html` mostrará un error de tabla no encontrada.

**¿Se puede acceder desde mobile?**
Sí, se agregó el botón hamburguesa en todos los archivos para mostrar/ocultar el sidebar en pantallas pequeñas.

---

*SIGO v2.0 — Documento de entrega*
*4ª Comisaría · Carabineros de Chile · Orden y Patria*
