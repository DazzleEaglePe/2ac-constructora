---
name: inventario-obras-ui
description: Lenguaje visual "Noche violeta" de la app móvil de Inventario de Obras (obras, activos, almacén, movimientos, usuarios). Úsalo SIEMPRE que diseñes, maquetes o programes cualquier pantalla, componente o prototipo de esta app (móvil o web), o cuando pidan "alinear al diseño", "mismo estilo", "dark violeta", "como las referencias".
---

# Inventario de Obras — lenguaje visual "Noche violeta"

App móvil para saber **dónde está cada herramienta y máquina, cuánto hay y quién la movió**.
El estilo toma como referencia conceptos de apps oscuras con acento violeta: fondo casi negro con un
brillo violeta sutil, tarjetas de vidrio, titulares grandes y livianos, píldoras redondeadas y barra
de navegación flotante. Inspiración, nunca copia de marcas ajenas.

## 1. Principios

1. **Oscuro y calmo**: fondo casi negro, un solo brillo violeta arriba a la derecha (y uno tenue abajo a la izquierda). Nada de lavados de color fuertes.
2. **Un acento, un apoyo**: violeta `#6C47FF` para la acción principal y lo destacado; lavanda `#C9B8FF` para lo seleccionado y los datos. El lima solo indica "en vivo" u "operativo".
3. **Titulares livianos**: grandes (32–36 px), peso 400, interletrado negativo. Los números grandes van en peso 300.
4. **Todo redondeado**: tarjetas de 22 px, filas de 18 px, botones y chips en píldora (999 px).
5. **Bento**: los resúmenes se arman en grillas de 2 columnas con una tarjeta violeta protagonista.
6. **La cifra manda**: en cada tarjeta, el número es lo más visible (cantidad, stock, unidades).

## 2. Tokens

| Token | Valor | Uso |
|---|---|---|
| `--bg` | `#0D0C13` | Fondo de pantalla |
| `--glow` | `rgba(108,71,255,0.38)` | Brillo radial superior |
| `--surface` | `rgba(255,255,255,0.04)` | Tarjetas y filas (vidrio) |
| `--surface-2` | `#15131D` | Paneles sólidos (footer, mapa) |
| `--line` | `rgba(255,255,255,0.09)` | Bordes de vidrio |
| `--text` | `#F4F2FA` | Texto principal |
| `--muted` | `#A7A3B8` | Texto secundario (contraste ≥ 7:1) |
| `--faint` | `#8A869C` | Placeholders |
| `--primary` | `#6C47FF` | Botón principal, tarjeta destacada, tab activo (texto blanco 5.3:1) |
| `--primary-hover` | `#5A35F0` | |
| `--lavender` | `#C9B8FF` | Selección, gráficos, eyebrow (texto oscuro `#17151F` encima) |
| `--live` | `#B4F05A` | Punto "En vivo" |

**Estados del activo** (siempre píldora con texto, nunca solo color):

| Estado | Fondo | Texto |
|---|---|---|
| Operativo | `rgba(180,240,90,0.14)` | `#C6F46A` |
| Mantenimiento | `rgba(255,181,71,0.15)` | `#FFC56B` |
| Baja | `rgba(255,107,107,0.15)` | `#FF8A80` |

Fondo de pantalla:

```css
background-color: #0D0C13;
background-image:
  radial-gradient(110% 55% at 85% -5%, rgba(108,71,255,0.38), transparent 60%),
  radial-gradient(70% 40% at -10% 105%, rgba(108,71,255,0.2), transparent 70%);
```

### Variante "Blanco y negro" (monocromo)

Mismos componentes y medidas. Solo cambian los tokens:

| Token violeta | Valor B/N | Nota |
|---|---|---|
| `--bg` `#0D0C13` | `#000000` | |
| `--glow` | `rgba(255,255,255,0.09)` (abajo `0.04`) | Brillo blanco apenas visible |
| `--surface-2` `#15131D` | `#111111` | |
| `--text` / `--muted` / `--faint` | `#F5F5F5` / `#A3A3A3` / `#8A8A8A` | |
| `--primary` `#6C47FF` | `#F4F4F4` | **Texto encima: `#0A0A0A`** (botón, tab activo, tarjeta destacada) |
| `--primary-hover` | `#D4D4D4` | |
| Texto secundario sobre primario `#EDE7FF` | `#404040` | |
| `--lavender` `#C9B8FF` | `#FAFAFA` | Selección; texto oscuro encima |
| Segundo tono de gráficos | `#8A8A8A` | Para que las series se distingan por luminosidad |
| Rellenos translúcidos sobre la tarjeta clara | `rgba(0,0,0,0.07–0.08)` | Nunca blanco translúcido sobre blanco |

Estados en monocromo (se distinguen por forma y luminosidad, siempre con texto):

| Estado | Estilo |
|---|---|
| Operativo | Relleno `#F5F5F5`, texto `#0A0A0A` |
| Mantenimiento | Fondo `rgba(255,255,255,0.1)`, borde de 1 px blanco al 40 %, texto `#F5F5F5` |
| Baja | Sin relleno, borde **punteado** `#6B6B6B`, texto `#A3A3A3` |

### Variante "Blanco" (fondo blanco, componentes negros)

Mismos componentes. Es la inversa de la variante B/N:

| Token violeta | Valor Blanco | Nota |
|---|---|---|
| `--bg` `#0D0C13` | `#FFFFFF` | Brillo `rgba(0,0,0,0.035)`, casi imperceptible |
| `--surface` / `--line` | `rgba(0,0,0,0.04)` / `rgba(0,0,0,0.09)` | Tarjetas gris muy claro con borde fino |
| `--surface-2` `#15131D` | `#F4F4F4` | Footer y mapa |
| `--text` / `--muted` / `--faint` | `#0A0A0A` / `#5C5C5C` / `#767676` | |
| `--primary` `#6C47FF` | `#0A0A0A` | Texto encima `#FFFFFF`; secundario `#BDBDBD` |
| `--primary-hover` | `#2A2A2A` | |
| `--lavender` `#C9B8FF` | `#0A0A0A` | Selección = relleno negro con texto blanco |
| Series de gráficos | `#0A0A0A` · `#8A8A8A` · `#D4D4D4` | |
| Barra de navegación | `rgba(255,255,255,0.94)` y sombra `rgba(0,0,0,0.12)` | Tab activo negro |
| Rellenos dentro de tarjetas negras | `rgba(255,255,255,0.16–0.2)` | |

Estados: **Operativo** relleno negro y texto blanco · **Mantenimiento** fondo blanco con borde negro de 1 px · **Baja** borde punteado `#A3A3A3` y texto `#6B6B6B`.

### Variante "Constructora A2C" (marca de la empresa) — recomendada para producción

Parte de la variante Blanco y suma el **amarillo de obra** de la marca A2C (logo negro, gris y amarillo; franja de seguridad).

| Token | Valor | Uso |
|---|---|---|
| `--brand-yellow` | `#FFC20E` | Botón principal (**texto negro**), FAB, punto "En vivo", pin del mapa, radio seleccionado, ícono destacado sobre tarjeta negra |
| `--brand-yellow-hover` | `#F2B200` | |
| `--brand-black` | `#0A0A0A` | Tarjetas destacadas (Almacén, resumen de obra, activo en Mover), tab activo, filtros seleccionados |
| Cifras sobre tarjeta negra | `#FFC20E` | Ej. "31 uds" del Almacén, "9" de la obra |
| Barra de navegación | Píldora **negra** `#0A0A0A`; tabs inactivos `#A3A3A3` | |
| Tab activo | **Píldora amarilla `#FFC20E` con ícono y texto negros** | Nunca negro sobre la barra negra: debe contrastar con la barra, no con la pantalla |
| Brillo de fondo | `rgba(255,194,14,0.16)` arriba, `0.07` abajo | |
| Franja de seguridad | `repeating-linear-gradient(-45deg, #FFC20E 0 12px, #0A0A0A 12px 24px)` | Solo como acento: parte superior del ingreso y pie de la tarjeta Almacén |

Estados: **Operativo** negro con texto blanco · **Mantenimiento** amarillo con texto negro (precaución) · **Baja** borde punteado gris.

Reglas: nunca texto amarillo sobre blanco (no llega a 4.5:1); el amarillo va como relleno con texto negro, o como texto sobre negro. Marca: "Constructora A2C", con el "2" en amarillo.

### Variantes oscuras de marca (misma estructura que Noche violeta)

Se reemplaza el violeta por un color de la marca A2C. **Regla clave:** con acentos cálidos (amarillo, naranja, dorado), el texto sobre el acento va **oscuro**, nunca blanco. "Mantenimiento" cambia de tono para no confundirse con el acento.

| Token | Noche A2C | Tierra | Grafito |
|---|---|---|---|
| `--bg` | `#0B0B0C` | `#120E09` | `#0F1216` |
| Brillo superior | `rgba(255,194,14,0.22)` | `rgba(243,146,0,0.30)` | `rgba(140,160,185,0.26)` + inferior dorado `0.10` |
| `--primary` (texto encima) | `#FFC20E` (`#0A0A0A`) | `#F39200` (`#140D05`) | `#E8B931` (`#0F1216`) |
| Secundario sobre primario | `#4A3A00` | `#4A2A00` | `#3F3210` |
| Selección (antes lavanda) | `#FFE08A` | `#FFC98A` | `#D8DEE6` (acero) |
| `--surface-2` | `#151515` | `#1A140D` | `#161A20` |
| Texto / secundario / placeholder | `#F5F5F2` / `#A6A6A0` / `#8A8A85` | `#F7F2EA` / `#B3A898` / `#8F8576` | `#F2F4F7` / `#A3ABB6` / `#858D99` |
| Mantenimiento | naranja `#FFA066` | amarillo `#FFD45C` | naranja `#FFA066` |

El ingreso de estas versiones lleva la marca "Constructora A2C" con el "2" en el color de acento, y la franja de seguridad arriba.

## 3. Tipografía

- **Geist** (Google Fonts) 300/400/500/600 para todo; **Geist Mono** para códigos (`HER-0142`, `MAQ-0007`).
- Escala: hero 34–36/1.05 (400, −0.025em) · título de sección 17 (500) · cuerpo 15–16 · meta 13 · micro 12.
- Cifras protagonistas: 44–56 px, peso 300, con la unidad al lado en 13 px `--muted` ("23 uds").
- Prohibidas: Inter, Roboto y Arial.

## 4. Componentes

- **Barra superior**: avatar circular (iniciales) · píldora central de estado ("● En vivo · hace 4 s") · botón circular de 44 px.
- **Hero**: eyebrow lavanda ("Buen día, Carlos") y un titular centrado de dos líneas.
- **Buscador**: input en píldora de 54 px de alto, de vidrio, con lupa.
- **Chips de acción rápida**: fila horizontal con scroll ("+ Herramienta o equipo", "+ Obra", "Mover activo").
- **Tarjeta de métrica**: vidrio de 160 px de ancho con título, subtítulo, un sparkline o curva lavanda y la cifra grande.
- **Tarjeta destacada**: fondo `--primary`, texto blanco y texto secundario `#EDE7FF`. Una por pantalla como máximo.
- **Filas de lista**: vidrio de 18 px de radio con ícono en círculo de 44 px, nombre, código mono, estado y cantidad a la derecha ("×2", peso 300).
- **Filtros**: grupo de píldoras. La activa va en lavanda con texto oscuro; las inactivas, en vidrio.
- **Opciones de radio** (origen/destino): fila de vidrio. La seleccionada lleva un borde lavanda de 1.5 px y fondo `rgba(108,71,255,0.18)`.
- **Stepper**: botones circulares de 48 px con la cifra central en 40 px, peso 300.
- **Navegación**: píldora flotante a 16 px de los bordes, con 3 destinos (Obras, Inventario, Usuarios). El activo lleva un relleno violeta con ícono y texto; los inactivos, solo ícono con `aria-label`.
- **FAB**: círculo violeta de 60 px con brillo, por encima de la navegación.
- **Mapa**: placeholder `--surface-2` con grilla tenue, calles más claras, pin violeta, chip de dirección y enlace "Abrir en Maps".
- **Bienvenida (splash → onboarding → ingreso)**, en la variante A2C va en **fondo blanco** (ingreso `#F6F6F4` con la hoja del formulario en blanco), con componentes negros y acento amarillo; sobre blanco, el amarillo va solo como relleno (chips, tarjetas, CTA, área del gráfico), nunca como texto; las líneas de los gráficos van en negro:
  - **Splash**: solo la marca "A2C" (el "2" en amarillo), centrada, con una barra de carga amarilla de 64 px y "CONSTRUCTORA" espaciado al pie.
  - **Onboarding de 3 pasos**: la ilustración son **tarjetas reales de la app** flotando y superpuestas (zona de 420 px).
    - Detrás van tarjetas "fantasma" rotadas ±3–8°, con opacidad 0.5 y desenfoque de 1.2 px.
    - Al frente va una tarjeta nítida con sombra y 1–2 chips flotantes (uno amarillo).
    - Abajo, el titular de 30 px en peso 500 y 3 líneas, los puntos de progreso (el activo es una píldora blanca de 18 px), el CTA amarillo a todo el ancho ("Continuar" / "Comenzar") y "Saltar ›" arriba a la derecha.
  - **Pasos**: 1) la tarjeta de una obra con chips y el Almacén; 2) el flujo vertical Almacén → tarjeta "Moviendo" con borde punteado → tarjeta amarilla "Asignado a…" con quién y cuándo; 3) la tarjeta del gráfico de unidades en obra con chips de mantenimiento e historial.
  - **Ingreso**: arriba un hero de 340 px con brillo amarillo, siluetas de edificios con franjas, la franja de seguridad y el ícono A2C de 76 px; debajo, una hoja `#161616` con radio de 24 px, campos DNI y contraseña, "Ingresar" amarillo y una lista de 3 beneficios con check amarillo.
- **Footer de acción**: panel `#15131D` con esquinas superiores de 28 px y botón primario en píldora a todo el ancho.

## 5. Reglas del dominio (no romper)

- **Máquina** → stock fijo **1**; al moverla, la cantidad está bloqueada en 1.
- **Herramienta** → por cantidad; al moverla, el usuario indica cuántas unidades (máximo: disponibles en el origen).
- Cada movimiento muestra **origen → destino, cantidad, usuario que lo hizo y fecha/hora** (tabla OBRA_ACTIVO).
- Ubicaciones posibles: cada **obra** (nombre, dueño, ubicación en el mapa) y el **Almacén central**.
- Estados del activo: Operativo, Mantenimiento y Baja.
- Usuario: DNI, nombre y contraseña.

## 6. Accesibilidad

- Áreas táctiles ≥ 44 px; botones reales (`<button>`, `<a href>`, `<input>` con `<label>`).
- `aria-label` en los botones que solo tienen ícono; `aria-pressed` en filtros y opciones.
- Texto ≥ 4.5:1 sobre el fondo; nunca usar `--faint` para información.
- Los estados se distinguen por texto además de por color.

## 7. Evitar

- Emojis como íconos (usar SVG de trazo de 2 px y `currentColor`).
- Más de una tarjeta violeta por bloque, o barras laterales de color en las tarjetas.
- Barras de estado falsas del sistema (9:41, batería).
- Datos inventados sin sentido; si falta un dato, usar `[PLACEHOLDER]`.
