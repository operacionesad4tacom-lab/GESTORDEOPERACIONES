# Control de Planes Operativos — SIGO

Módulo para registrar y controlar los planes y órdenes que llegan por DOE a la 4ta. Comisaría Chacalluta (F):
qué servicios vienen, cuándo, dónde, con cuánto personal y medios, y qué plazos vencen.

Todo se **ingresa a mano** (sin extracción automática ni servicios de IA externos). Lo que un documento no
indica se deja en blanco y se muestra como **“No especificado”**; el sistema nunca rellena valores supuestos.

## Estado de avance

| Etapa | Contenido | Estado |
|---|---|---|
| 1 | Base de datos, seguridad, semilla P1–P8, lista de planes, bandeja “Por revisar”, ficha y formulario manual, adiciones por NCU, plantillas, auditoría | ✅ Lista |
| 2 | Panel hoy + 72 h, calendario, línea de tiempo, carga diaria por unidad, vista por unidad, plazos | Pendiente |
| 3 | Alertas (campana) y tarea programada cada 15 min | Pendiente |
| 4 | Labor desarrollada (formulario móvil), consolidado y exportaciones Excel / Word / PDF | Pendiente |

## Instalación

1. Entrar a **Supabase → SQL Editor** del proyecto SIGO.
2. Ejecutar, **en este orden**, el contenido de cada archivo y presionar **Run**:
   1. `sql/planes_01_esquema.sql` — tablas, auditoría y unidades base.
   2. `sql/planes_02_seguridad.sql` — permisos por rol y unidad.
   3. `sql/planes_03_semilla.sql` — *(opcional)* los 8 planes de prueba P1–P8, ya confirmados.
3. Los scripts se pueden volver a ejecutar sin duplicar datos.
4. Abrir **Planes Operativos** desde el menú lateral de SIGO.

> El perfil del usuario se guarda durante la sesión: después de cambiar un rol, el usuario debe **cerrar sesión y volver a entrar**.

## Roles

El módulo usa los usuarios existentes. Sin configuración adicional:

| Rol en SIGO (`users.rol`) | Rol en el módulo | Puede |
|---|---|---|
| ADMIN, OPERACIONES | Administrador de Operaciones | Todo: crear, editar, confirmar, eliminar |
| USUARIO | Consulta | Ver planes confirmados (solo lectura) |

Para asignar un **Jefe de destacamento** (ve los planes donde participa su unidad y, en la etapa 4, registra labor),
ejecutar en el SQL Editor, reemplazando el nombre y la unidad:

```sql
update users
set planes_rol = 'jefe_destacamento',
    planes_unidad_id = (select id from po_unidades where sigla = 'Tcia. Visviri')
where nombre = 'Nombre del Jefe';
```

Siglas de unidades cargadas: `4ta Com.`, `SIP 4ta Com.`, `Tcia. Chungará`, `Tcia. Visviri`, `Retén Chucuyo`,
`Retén Tacora`, `Retén Guallatire`, `Retén Chilcaya`, `Tcia. Carretera`, `OS7`, `OS9`.
Para agregar otra: `insert into po_unidades (nombre, sigla, propia) values ('Nombre completo', 'Sigla', true);`

Los permisos se aplican en la base de datos (RLS), no solo en la pantalla: un usuario de Consulta no puede
modificar datos aunque manipule la página, y nadie puede asignarse a sí mismo un rol del módulo.

## Uso

### Ingresar un plan
1. **Planes Operativos → ＋ Nuevo plan.** Completar los datos del DOE y del plan; dejar en blanco lo no indicado.
2. Si el NCU o el N° de plan (del mismo emisor) ya existe, el sistema ofrece **“Agregar como adición”** en vez de
   crear un duplicado.
3. El plan queda en la pestaña **Por revisar**: no aparece en las vistas ni genera alertas de servicio.
4. En la ficha, agregar **facciones** (puntos de control), los **recursos** de cada unidad (personal por grado y
   medios) y los **servicios** (fechas y horarios; se pueden crear varias fechas de una vez, por lista o por rango,
   y turnos que cruzan la medianoche).
5. Registrar **plazos**, **indicadores personalizados** y, si los documentos no coinciden, **contradicciones**.
6. Presionar **✅ Confirmar plan**.

### Adiciones (nuevo DOE sobre un plan existente)
En la ficha, **➕ Registrar adición (DOE)**: indicar el NCU, su fecha y resumen, y modificar solo los datos que
cambian. El historial del NCU muestra cada cambio como *antes → después*.

### Plantillas
**📄 Guardar como plantilla** copia facciones, recursos, indicadores y plazos sin fechas. Para reutilizarla:
**Planes Operativos → Desde plantilla**, y luego completar fechas y responsables.

### Estados
Se calculan solos a partir de los servicios y plazos:

| Estado | Cuándo |
|---|---|
| Por revisar | Ingresado y aún no confirmado |
| Próximo | Su próximo servicio aún no comienza |
| En curso | Hay un servicio en desarrollo (o vigente hasta nueva orden) |
| Pendiente de labor | Terminaron sus servicios y hay un plazo de labor pendiente |
| Finalizado | Terminado y sin labor pendiente |
| Cerrado | Cerrado manualmente por el administrador |

### Auditoría
Toda creación, edición, confirmación y borrado queda registrada (tabla `po_auditoria`). El administrador la ve
en la ficha, sección **Historial de cambios**.

## Archivos del módulo

| Archivo | Contenido |
|---|---|
| `planes.html` | Lista de planes, bandeja “Por revisar” y plantillas |
| `planes-ficha.html` | Ficha del plan: ingreso manual, edición, adiciones, confirmación |
| `js/planes.js` | Lógica compartida: fechas en America/Santiago, estados, recursos, acceso a datos, formularios |
| `css/planes.css` | Estilos del módulo (misma paleta de SIGO) |
| `sql/planes_0*.sql` | Esquema, seguridad y semilla |
| `tests/planes.test.mjs` | Pruebas de la lógica (`node --test tests/planes.test.mjs`) |

El resto de SIGO no se modificó, salvo el enlace **Planes Operativos** agregado al menú lateral.
