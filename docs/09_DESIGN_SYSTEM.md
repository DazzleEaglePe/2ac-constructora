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
| Lema             | "Tu visión — nuestra ejecución"                                                          |
| Monograma        | "A2C" geométrico en bloques: A y C negras, **"2" amarillo** escalonado (provisorio hasta el rebranding) |
| Recursos         | `assets/branding/a2c-logo-1080x1080.mp4`, `a2c-logo-vertical-1080x1920.mp4`, `a2c-logo-540.gif` |
| Franja de seguridad | `repeating-linear-gradient(-45deg, #FFC20E 0 12px, #0A0A0A 12px 24px)` — solo como acento (ingreso, cierre de la animación) |

> El logo definitivo llegará con el rebranding. Todo lugar donde aparece el monograma usa el widget `A2CLogo`, así que cambiarlo es un solo reemplazo.

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

## 8. Animación del logo (splash)

Bucle de **6,5 s** a 30 fps lógicos (60 fps de render). Monograma A2C en un lienzo de 720×720 (escalado al ancho de pantalla). Curva principal `Cubic(0.7, 0, 0.2, 1)`; los cambios de fondo son **cortes secos**.

| Tramo (s)  | % del ciclo | Fondo      | Acción                                                                                 |
| ---------- | ----------- | ---------- | -------------------------------------------------------------------------------------- |
| 0,00–0,52  | 0–8 %       | `#E6E6E3`  | Monograma visible; rebote de escala 1 → 0,9 → 1,05 → 1                                 |
| 0,52–1,43  | 8–22 %      | `#FFC20E`  | El "2" pasa a negro; la **A se estira** a la izquierda (scaleX 7) y la **C** a la derecha (scaleX 4); vuelven |
| 1,43–2,60  | 22–40 %     | `#0A0A0A`  | A y C pasan a blanco; una **viga amarilla** inclinada 20° barre la pantalla              |
| 2,40–2,73  | 37–42 %     | —          | **Barrido de la franja de seguridad** cubre el corte de color                           |
| 2,60–3,51  | 40–54 %     | `#FFFFFF`  | El **"2" crece** hasta escala 5 y vuelve                                                |
| 3,51–5,72  | 54–88 %     | `#F3F0E8`  | El monograma sube 40 px y baja a escala 0,7; **CONSTRUCTORA** se revela de izquierda a derecha; barra amarilla; lema con fundido |
| 5,72–6,50  | 88–100 %    | `#E6E6E3`  | El texto sale y el monograma vuelve al centro                                           |

**Implementación Flutter:** `A2CSplashAnimation` = `AnimationController(duration: 6.5 s)` + `CustomPainter` con los trazados del monograma (coordenadas en `09` anexo A) e `Interval` por tramo. Si `MediaQuery.disableAnimations` es verdadero, se muestra el estado final estático. En usos posteriores, el splash se corta cuando la sesión está verificada (mínimo 1,5 s).

### Anexo A — trazados del monograma (viewBox 320×120)

```
A: M0 120 L44 0 L84 0 L128 120 L96 120 L86 92 L42 92 L32 120 Z  M50 68 L78 68 L64 28 Z  (even-odd)
2: M136 0 L224 0 L224 70 L170 70 L170 94 L224 94 L224 120 L136 120 L136 50 L190 50 L190 26 L136 26 Z
C: M320 0 L232 0 L232 120 L320 120 L320 92 L262 92 L262 28 L320 28 Z
```

## 9. Onboarding e ingreso

| Pantalla    | Especificación                                                                                       |
| ----------- | ---------------------------------------------------------------------------------------------------- |
| Onboarding  | Fondo blanco. Zona de ilustración de 420 px con **tarjetas reales de la app** (frontal nítida con sombra; tarjetas "fantasma" detrás rotadas ±3–8°, opacidad 0,5, desenfoque 1,2 px); titular `headline` en 3 líneas; puntos (activo: píldora negra 18 px); CTA amarillo a todo el ancho; "Saltar ›" arriba a la derecha. Entrada: tarjetas suben 24 px con fundido (600 ms); texto con 100 ms de retraso. |
| Ingreso     | Fondo `#F6F6F4`. Hero de 340 px: brillo amarillo radial, siluetas de edificios con franjas, franja de seguridad superior, ícono A2C 76 px (negro con "2" amarillo), "Constructora **A2C**" (A2C sobre etiqueta amarilla) y subtítulo. Hoja blanca radio 24 con DNI, contraseña, "Ingresar" y 3 beneficios con check negro en círculo amarillo. |

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
