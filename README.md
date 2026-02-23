# SIGO — Sistema Integral de Gestión Operacional
## 4ª Comisaría — Carabineros de Chile

---

## ¿QUÉ INCLUYE ESTE PAQUETE?

```
SIGO/
├── index.html          ← Dashboard principal
├── login.html          ← Pantalla de acceso
├── tareas.html         ← Tareas, cuentas y Kanban
├── calendario.html     ← Calendario mensual operacional
├── documentos.html     ← Gestión de DOE con flujo padre-hijo
├── rutinas.html        ← Rutinas de supervisión
├── formatos.html       ← Biblioteca de formatos oficiales
├── avisos.html         ← Información permanente
├── usuarios.html       ← Gestión de usuarios
├── css/styles.css      ← Estilos (paleta verde Carabineros)
├── js/supabase.js      ← Toda la lógica de datos
├── assets/escudo.jpg   ← Logo Carabineros de Chile
└── supabase_schema.sql ← Base de datos completa
```

---

## PASOS DE INSTALACIÓN

### PASO 1 — Crear cuenta en Supabase (gratuito)

1. Ir a https://supabase.com
2. Crear cuenta con correo
3. Crear nuevo proyecto:
   - Nombre: `sigo-4comisaria`
   - Contraseña: una segura (guárdala)
   - Región: `South America (São Paulo)` → más cercano a Chile

### PASO 2 — Ejecutar el SQL

1. En el panel de Supabase, ir a **SQL Editor**
2. Pegar el contenido de `supabase_schema.sql`
3. Presionar **Run** (▶)
4. Verificar que no hubo errores

### PASO 3 — Configurar Storage

1. En Supabase, ir a **Storage**
2. Crear nuevo bucket: `sigo-archivos`
3. Marcarlo como **Public** (para que los formatos sean descargables)

### PASO 4 — Obtener las credenciales

1. En Supabase, ir a **Settings → API**
2. Copiar:
   - **Project URL** → `https://xxxx.supabase.co`
   - **anon public key** → llave larga que empieza con `eyJ...`

### PASO 5 — Configurar el sistema

Abrir el archivo `js/supabase.js` y reemplazar las líneas 5 y 6:

```javascript
const SUPABASE_URL = 'https://TU_PROYECTO.supabase.co';   // ← Cambiar
const SUPABASE_KEY = 'TU_ANON_KEY_AQUI';                  // ← Cambiar
```

### PASO 6 — Crear el primer usuario (Admin)

1. En Supabase, ir a **Authentication → Users**
2. Click **Add user → Create new user**
3. Ingresar correo y contraseña
4. Copiar el **UUID** generado (columna "UID")

5. Abrir el sistema en el navegador → `index.html`
6. Ir a **Usuarios** en el menú
7. Click **Nuevo Usuario**
8. Pegar el UUID copiado
9. Ingresar nombre, grado y seleccionar rol **ADMIN**

### PASO 7 — Usar el sistema

Abrir `login.html` en el navegador e ingresar con el correo y contraseña creados.

---

## PUBLICAR EN INTERNET (OPCIONAL)

Para acceder desde cualquier PC o celular sin instalar nada:

### Opción A — GitHub Pages (100% gratuito)

1. Crear cuenta en https://github.com
2. Crear repositorio nuevo (público)
3. Subir todos los archivos de la carpeta SIGO
4. Ir a Settings → Pages → Branch: main
5. El sistema estará en: `https://tu-usuario.github.io/sigo/login.html`

### Opción B — Netlify (también gratuito)

1. Ir a https://netlify.com
2. Arrastrar la carpeta SIGO completa
3. En segundos tendrás una URL pública

---

## CONFIGURACIONES RECOMENDADAS INICIALES

Una vez funcionando, crear estas rutinas desde el módulo de Rutinas:

| Rutina | Frecuencia | Criticidad |
|--------|------------|------------|
| Panel Comando y Control | Diaria | Crítica |
| Estado de Fuerza | Diaria | Crítica |
| Estadísticas Semanales | Semanal | Alta |
| Mapa de Contingencia | Semanal | Alta |
| Informe Mensual | Mensual | Normal |

---

## PREGUNTAS FRECUENTES

**¿El sistema guarda datos en internet?**
Sí, en Supabase que es seguro, encriptado y con respaldo automático.

**¿Funciona en el celular?**
Sí, es responsive. Se adapta a pantallas pequeñas.

**¿Pueden usarlo varios al mismo tiempo?**
Sí, todos con su usuario y contraseña acceden al mismo sistema.

**¿Se puede cambiar el nombre de la unidad?**
Sí, en cada archivo HTML busca `4ª Comisaría — Operaciones` y cámbialo.

**¿Qué pasa si Supabase deja de funcionar?**
El plan gratuito incluye SLA y backups. Para uso institucional se recomienda el plan Pro (~$25/mes).

---

## SOPORTE TÉCNICO

Este sistema fue construido en HTML + JavaScript puro conectado a Supabase.
No requiere servidor propio, compiladores ni instalaciones especiales.
Cualquier persona con conocimientos básicos de web puede modificarlo.

---

*ORDEN Y PATRIA — Uso exclusivo personal autorizado*
