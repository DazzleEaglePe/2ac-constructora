# 09 — Sistema de Diseño

> **Versión elegida:** "Constructora A2C" — fondo blanco, componentes negros y acento amarillo de obra.
> **Canvas:** <https://claude.ai/artifact/NSoVekPv3gJuHQjkXjqrpk> (página Constructora A2C)
> **Implementación:** `apps/mobile/lib/core/theme/` (`A2CColors`, `A2CTypography`, `A2CTheme`)
> **Reglas para agentes:** [`.claude/skills/inventario-obras-ui/SKILL.md`](../.claude/skills/inventario-obras-ui/SKILL.md)

---

## 1. Principios

1. **Legible a pleno sol:** fondo blanco, texto negro, alto contraste. El amarillo es relleno, nunca texto sobre blanco.
2. **La cifra manda:** en cada tarjeta, la cantidad es lo más visible (stock, unidades).
3. **Todo redondeado y táctil:** tarjetas de 22 px, botones en píldora, áreas ≥ 48 dp.
4. **Rápido en obra:** acciones principales a un toque (Mover, + Activo, + Obra).
5. **Marca presente, no invasiva:** la marca A2C vive en el splash, el onboarding y el ingreso; dentro de la app solo el acento amarillo.

## 2. Marca

| Elemento         | Valor                                                                                   |
| ---------------- | --------------------------------------------------------------------------------------- |
| Nombre           | Constructora A2C **[POR CONFIRMAR vs. "A2 Constructora", P1]**                           |
| Lema             | "TU VISIÓN · NUESTRA EJECUCIÓN" (Montserrat Medium, espaciado amplio)                    |
| Logo "Cota"      | Monograma de una **A** en dos hojas que se tocan en el vértice (separadas por una línea fina; la derecha cortada en paralelo a la diagonal del 2) y un **"2" amarillo** geométrico, rodeados de **cotas** de plano: marco de extensión, cotas con flechas arriba e izquierda, cadena de cotas a la derecha y cota inferior. Logotipo "A2 CONSTRUCTORA" en Montserrat Black. Monograma de 250,8 × 160 u; con cotas, caja de 330 × 247 u |
| Versiones        | Vertical (principal), horizontal, reverso sobre negro, monocromo, sobre amarillo, símbolo con cotas y **símbolo simplificado sin cotas** para tamaños pequeños (< 40 px, ícono de la app) |
| Fuente del logo  | Illustrator `PROPUESTAS_AI.aic`, mesa "02 - Cota" (logotipo, retícula y variantes) |
| Recursos         | `assets/branding/a2c-logo-1080x1080.mp4`, `a2c-logo-vertical-1080x1920.mp4`, `a2c-logo-540.gif` |
| Franja de seguridad | `repeating-linear-gradient(-45deg, #FFC20E 0 12px, #0A0A0A 12px 24px)` — solo como acento (ingreso, cierre de la animación) |

> Todo lugar donde aparece el logo usa el widget `A2CLogo` (`cotas: true` para la versión con cotas); la geometría vive en `A2CMark` (anexo A).

## 3. Color

### Tokens base

| Token               | Hex        | Uso                                                            |
| ------------------- | ---------- | -------------------------------------------------------------- |
| `brandYellow`       | `#FFC20E`  | Botón principal, tab activo, FAB, chips destacados, pin del mapa |
| `brandYellowPressed`| `#F2B200`  | Estado presionado / hover                                      |
| `brandYellowSoft`   | `#FFF3C4`  | Fondos suaves de resaltado                                     |
| `ink`               | `#0A0A0A`  | Texto principal, tarjetas destacadas, barra de navegación      |
| `inkSecondary`      | `#5C5C5C`  | Texto secundario (7:1 sobre blanco)                            |
| `inkTertiary`       | `#767676`  | Placeholders (4,5:1)                                           |
| `goldText`          | `#7A5A00`  | Cifras de acento sobre fondo claro (en vez de amarillo)        |
| `background`        | `#FFFFFF`  | Fondo de pantallas                                             |
| `backgroundAlt`     | `#F6F6F4`  | Fondo del ingreso y secciones                                  |
| `surface`           | `rgba(0,0,0,0.04)` | Tarjetas                                               |
| `surfaceStrong`     | `#F4F4F4`  | Paneles inferiores, mapa                                       |
| `border`            | `rgba(0,0,0,0.09)` | Bordes de tarjeta                                      |
| `onYellow`          | `#0A0A0A`  | Texto sobre amarillo                                           |
| `onInk`             | `#FFFFFF`  | Texto sobre negro                                              |
| `onInkSecondary`    | `#BDBDBD`  | Texto secundario sobre negro                                   |

### Estados del activo

| Estado        | Fondo       | Texto       | Forma                       |
| ------------- | ----------- | ----------- | --------------------------- |
| Operativo     | `#0A0A0A`   | `#FFFFFF`   | Píldora sólida              |
| Mantenimiento | `#FFC20E`   | `#0A0A0A`   | Píldora sólida (precaución) |
| Baja          | transparente| `#6B6B6B`   | Borde punteado `#A3A3A3`    |

### Reglas de color

- ❌ Texto amarillo sobre blanco (contraste 1,6:1).
- ✅ Amarillo como relleno con texto negro, o texto amarillo sobre negro.
- ✅ Una sola tarjeta destacada (negra) por bloque.
- ✅ Series de gráficos: negro, `#8A8A8A`, `#D4D4D4` y amarillo como área.

## 4. Tipografía

**Geist** (Vercel, licencia OFL) empaquetada en `assets/fonts/`. **Geist Mono** para códigos.

| Estilo        | Tamaño / interlineado | Peso | Uso                                   |
| ------------- | --------------------- | ---- | ------------------------------------- |
| `display`     | 34 / 1.08             | 700  | Titulares de onboarding               |
| `headline`    | 30 / 1.15             | 500  | Títulos de pantalla ("Inventario")    |
| `title`       | 18 / 1.3              | 600  | Títulos de tarjeta, nombre de obra    |
| `body`        | 16 / 1.45             | 400  | Texto general                         |
| `bodyStrong`  | 15 / 1.4              | 600  | Botones, etiquetas importantes        |
| `label`       | 13 / 1.3              | 500  | Etiquetas de campo, metadatos         |
| `caption`     | 12 / 1.3              | 500  | Notas, fechas                         |
| `overline`    | 12 / 1.2, +0.14em     | 600  | "01 — UBICACIÓN", "CONSTRUCTORA"      |
| `metric`      | 48 / 1.0, −0.03em     | 300  | Cifras protagonistas (23 uds)         |
| `code`        | 12 / 1.2 (Geist Mono) | 500  | `HER-0142`                            |

## 5. Espaciado, radios y elevación

| Token        | Valor                                   |
| ------------ | --------------------------------------- |
| Escala       | 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40     |
| Margen lateral | 16 (pantallas) · 24 (onboarding)      |
| Radios       | `sm` 12 (inputs) · `md` 18 (filas) · `lg` 22 (tarjetas) · `xl` 28 (paneles inferiores) · `pill` 999 |
| Sombra tarjeta flotante | `0 24 50 rgba(0,0,0,0.12)`   |
| Sombra barra de navegación | `0 12 30 rgba(0,0,0,0.22)` |
| Sombra CTA amarillo | `0 10 24 rgba(242,178,0,0.45)`   |

## 6. Iconografía

- Íconos de trazo 2 px, extremos redondeados, 20–24 px (set **Lucide** vía `lucide_icons_flutter`).
- Íconos propios: máquina (engranaje), herramienta (llave), almacén, obra (casa), movimiento (flechas ⇄).
- Nunca emojis.

## 7. Componentes

| Componente            | Especificación                                                                                     | Widget Flutter          |
| --------------------- | -------------------------------------------------------------------------------------------------- | ----------------------- |
| Botón principal       | Píldora amarilla, 54 h, texto negro 16/600; presionado `#F2B200`; deshabilitado 40 % opacidad       | `A2CPrimaryButton`      |
| Botón secundario      | Píldora `surface` con borde, texto negro                                                            | `A2CSecondaryButton`    |
| Botón ícono           | Círculo 44, `surface` + borde, `Semantics` obligatorio                                              | `A2CIconButton`         |
| Campo de texto        | 52 h, radio 14, borde `rgba(0,0,0,.12)`, foco con borde negro 2 px, etiqueta visible arriba         | `A2CTextField`          |
| Tarjeta de obra       | Radio 22, `surface`, nombre + dirección + chips de activos + pie (dueño, unidades, último mov.)    | `SiteCard`              |
| Tarjeta destacada     | Fondo negro, texto blanco, cifra en amarillo, círculo de ícono amarillo                            | `HighlightCard`         |
| Tarjeta de métrica    | 168 ancho, título, subtítulo, mini gráfico, cifra `metric`                                          | `MetricCard`            |
| Fila de activo        | Radio 18, ícono en círculo 44, nombre, código mono, estado, cantidad a la derecha                   | `AssetRow`              |
| Chip                  | Píldora, `rgba(0,0,0,.06)`, 13 px; cantidad en `goldText`                                           | `A2CChip`               |
| Píldora de estado     | Ver §3 Estados                                                                                      | `StatusBadge`           |
| Chip de observación   | Fondo `#FFF3C4`, ícono de alerta y texto negro; "Atendida" pasa a gris con check                    | `ObservationChip`       |
| Filtros segmentados   | Contenedor píldora; opción activa negra con texto blanco                                           | `A2CSegmented`          |
| Opción de radio       | Fila 56 h; seleccionada con borde negro 1,5 px y punto negro con centro amarillo                     | `A2CRadioTile`          |
| Stepper               | Botones circulares 48, cifra central 40/300                                                        | `QuantityStepper`       |
| Barra de navegación   | Píldora negra flotante (16 px de los bordes); **tab activo: píldora amarilla con ícono y texto negros**; inactivos `#A3A3A3` | `A2CNavBar` |
| FAB                   | Círculo amarillo 60 con sombra amarilla, ícono "+" negro                                            | `A2CFab`                |
| Panel inferior de acción | `surfaceStrong`, radio superior 28, CTA a todo el ancho                                         | `ActionFooter`          |
| Mapa                  | Contenedor radio 22, pin amarillo con borde negro, chip de dirección, "Abrir en Maps"               | `SiteMap`               |
| Indicador en vivo     | Punto amarillo con halo + "En vivo · hace N s"                                                      | `LiveIndicator`         |
| Banda sin conexión    | Banda superior gris oscuro: "Sin conexión · datos de hace N min"                                     | `OfflineBanner`         |

## 8. Animación de entrada (splash) — "Trazado"

Fondo blanco con la franja de seguridad arriba. Se reproduce **una vez** (≈2,7 s en la app, 1,2× la velocidad del canvas) y sale cuando además la sesión está verificada; un toque la salta. Opción A del canvas (las opciones B "Plano a obra" y C "Ensamble" quedaron como alternativas).

| Tramo (s de diseño) | Acción | Curva |
| ------------------- | ------ | ----- |
| 0,00–1,01 | Se dibujan el marco y las marcas finas, una tras otra (30 ms de desfase) | `Cubic(0.6, 0, 0.2, 1)` |
| 0,42–1,39 | Se dibujan las líneas de cota (50 ms de desfase) | `Cubic(0.6, 0, 0.2, 1)` |
| 0,99–1,30 | Las flechas aparecen y crecen de 0,6 a 1 | `ease` |
| 1,14–2,03 | Las hojas de la A suben 10 u mientras se descubren desde la base (la derecha 0,26 s después) | `Cubic(0.2, 0.8, 0.2, 1)` |
| 1,72–2,44 | El 2 se llena de izquierda a derecha | `Cubic(0.7, 0, 0.2, 1)` |
| 2,39–2,91 | "A2 CONSTRUCTORA" entra con fundido y subida de 12 px | `Cubic(0.2, 0.8, 0.2, 1)` |
| 2,70–3,22 | El lema entra con fundido y subida de 8 px | `ease` |

**Implementación Flutter:** `A2CSplashAnimation` (`SplashTimeline` + `SplashPainter` sobre `A2CMark`). Con `MediaQuery.disableAnimations` se muestra el final de inmediato.

### Anexo A — trazados del monograma "Cota" (unidades del manual)

```
Hoja izquierda: M0 160L85.4 0L85.4 69.13L36.9 160Z
Hoja derecha:   M88.1 0L139.07 98.97L112.05 119.33L88.1 72.82Z
2:              M139.2 2.2L212.7 2.2A38.1 38.1 0 0 1 250.8 40.3L250.8 47A29.8 29.8 0 0 1 238.93 70.8L162.63 128.3L243.4 128.3L243.4 160L112.28 160L112.28 128.3L214.99 50.9A6.8 6.8 0 0 0 217.7 45.47L217.7 41.3A8.9 8.9 0 0 0 208.8 32.4L139.2 32.4Z
Caja con cotas: -40 -54 330 247 (líneas finas 1 u, cotas 1,5 u, flechas 13 × 8,6 u)
```

## 9. Onboarding e ingreso

| Pantalla    | Especificación                                                                                       |
| ----------- | ---------------------------------------------------------------------------------------------------- |
| Onboarding  | Fondo blanco. Zona de ilustración de 420 px con **tarjetas reales de la app** (frontal nítida con sombra; tarjetas "fantasma" detrás rotadas ±3–8°, opacidad 0,5, desenfoque 1,2 px); titular `headline` en 3 líneas; puntos (activo: píldora negra 18 px); CTA amarillo a todo el ancho; "Saltar ›" arriba a la derecha. Entrada: tarjetas suben 24 px con fundido (600 ms); texto con 100 ms de retraso. |
| Ingreso (v2) | Cabecera negra `#0A0A0A` con franja de seguridad de 6 px, cotas del logo en blanco al 13 % como plano de fondo, botón volver (44 px, borde blanco 22 %), símbolo Cota sobre negro (A blanca, 2 amarillo), título "Ingresa a tu cuenta" 32 px y bajada blanca al 72 %. Hoja blanca con radio superior 28 que sube sobre la cabecera: pestaña única "Ingreso con DNI" con subrayado negro de 3 px, campos con etiqueta arriba e ícono (DNI con contador n/8 y ayuda "Ingrese su nro de documento."; contraseña con ojo), borde negro y halo amarillo al enfocar, casilla "Recordar mi DNI en este equipo" (relleno amarillo, check negro), "Ingresar" amarillo y el pie "o solicita tu usuario con tu administrador". Artboard "Ingreso v2 · referencia · A2C" del canvas. |

## 10. Movimiento (motion)

| Uso                     | Duración | Curva                    |
| ----------------------- | -------- | ------------------------ |
| Transición de pantalla  | 300 ms   | `Curves.easeOutCubic`    |
| Tab activo              | 200 ms   | `Curves.easeOut`         |
| Hojas inferiores        | 250 ms   | `Curves.easeOutCubic`    |
| Destello de actualización en vivo | 900 ms | `Curves.easeOut`  |
| Entrada de onboarding   | 600 ms   | `Cubic(0.2, 0.8, 0.2, 1)`|

## 11. Implementación de tokens (Flutter)

```dart
abstract final class A2CColors {
  static const brandYellow = Color(0xFFFFC20E);
  static const brandYellowPressed = Color(0xFFF2B200);
  static const ink = Color(0xFF0A0A0A);
  static const inkSecondary = Color(0xFF5C5C5C);
  static const inkTertiary = Color(0xFF767676);
  static const goldText = Color(0xFF7A5A00);
  static const background = Color(0xFFFFFFFF);
  static const backgroundAlt = Color(0xFFF6F6F4);
  static const surface = Color(0x0A000000);      // 4 %
  static const border = Color(0x17000000);       // 9 %
}

abstract final class A2CRadii {
  static const sm = 12.0, md = 18.0, lg = 22.0, xl = 28.0, pill = 999.0;
}
```

`A2CTheme.light()` construye el `ThemeData` (Material 3, `useMaterial3: true`) con estos tokens; ningún widget usa colores literales.
