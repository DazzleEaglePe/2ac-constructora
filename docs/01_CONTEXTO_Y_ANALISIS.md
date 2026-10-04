# 01 — Contexto y Análisis

> **Cliente:** Constructora A2C ("Tu visión – nuestra ejecución")
> **Producto:** A2C Inventario — control de herramientas y maquinaria por obra
> **Versión del documento:** 1.0 · 2026-10-04

---

## 1. Problema

Constructora A2C trabaja en varias obras a la vez y abastece a cada una desde un almacén central. Hoy el control de herramientas y máquinas se hace de memoria, por WhatsApp o en hojas sueltas. Consecuencias:

| Síntoma                                                     | Impacto                                         |
| ----------------------------------------------------------- | ----------------------------------------------- |
| No se sabe en qué obra está una herramienta concreta        | Tiempo perdido buscando, llamadas entre obras   |
| Herramientas que "desaparecen" sin responsable              | Pérdidas económicas y reposiciones no previstas |
| Se compran equipos que ya existen en otra obra              | Gasto duplicado                                 |
| Máquinas en mantenimiento enviadas por error a obra         | Paradas de trabajo, riesgos de seguridad        |
| No hay historial de quién movió qué y cuándo                | Imposible auditar o asignar responsabilidad     |

## 2. Objetivo del producto

Dar a la constructora **una sola fuente de verdad** sobre su inventario de activos, accesible desde el celular en obra, que responda en segundos tres preguntas:

1. **¿Dónde está?** — ubicación actual de cada activo (obra o almacén) y cantidades.
2. **¿Cuánto hay?** — stock total y por ubicación, con estado (operativo, mantenimiento, baja).
3. **¿Quién lo movió?** — historial inmutable de movimientos con usuario, fecha, hora y nota.

### Objetivos medibles (primeros 3 meses de uso)

| Métrica                                                       | Meta        |
| ------------------------------------------------------------- | ----------- |
| Activos registrados respecto del inventario físico            | ≥ 95 %      |
| Movimientos registrados en la app vs. traslados reales        | ≥ 90 %      |
| Tiempo para registrar un movimiento                           | ≤ 30 s      |
| Tiempo para encontrar la ubicación de un activo               | ≤ 10 s      |
| Diferencia entre inventario de la app y conteo físico mensual | ≤ 3 %       |

## 3. Usuarios y roles

> **Decisión de A2C (2026-10-04):** dos roles, **Administrador** y **Operador**. Puede haber más de un administrador (normalmente dos).

| Rol               | Quién es                                              | Qué hace                                                                                     |
| ----------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Administrador** | Gerencia / responsables de la constructora            | **Administra y supervisa**: gestiona usuarios, obras y catálogo, visualiza el inventario, atiende observaciones y audita. Tiene acceso a todas las funciones, pero **no ejecuta los traslados** en el día a día |
| **Operador**      | Equipo de movilización                                | **Único rol operativo**: consulta la disponibilidad, **ejecuta y registra los traslados** entre **cualquier obra** y el almacén y **reporta observaciones** durante el traslado. **No necesita aprobación del administrador** |

### Flujo actual vs. flujo con la app

| Antes (por llamadas)                                                                 | Con A2C Inventario                                                              |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| El responsable de una obra llama a la obra A, a la obra B, etc., para saber si alguien tiene la herramienta disponible | El operador **busca la herramienta** y ve al instante en qué obras y en el almacén está, y cuántas unidades hay |
| Se coordina el traslado de palabra, sin registro                                     | El operador ejecuta el traslado **sin pedir aprobación** y lo **registra en la app** (origen → destino, cantidad, quién, cuándo y observaciones si las hay) |
| Nadie sabe con certeza dónde quedó cada herramienta                                  | El inventario se actualiza **en tiempo real** para todos                        |

> El acceso **no se limita por obra**: no existe el rol de encargado de obra. Los operadores pueden mover entre todas las obras.

### Contexto de uso

- Uso principal **en obra, desde el celular**, con guantes, a pleno sol y con señal irregular → interfaz de alto contraste, áreas táctiles grandes, **tolerancia a la falta de conexión**.
- Uso secundario en oficina (consulta, reportes) → panel web en el roadmap posterior al MVP.

## 4. Alcance

### Dentro del MVP

- Ingreso con DNI y contraseña; splash con logo animado y onboarding de 3 pasos.
- Gestión de **usuarios** (alta, edición, desactivación) con dos roles: Administrador y Operador.
- **Consulta de disponibilidad**: dónde está cada herramienta y cuántas hay, sin llamar a las obras.
- **Observaciones** reportadas por el operador durante el traslado.
- Gestión de **obras** (nombre, dueño, ubicación en mapa) y del **almacén central**.
- Catálogo de **activos**: máquinas (unidad única) y herramientas (por cantidad), con código automático, estado y notas.
- **Mover o asignar** activos entre almacén y obras, con validación de stock.
- **Historial de movimientos** por activo y por obra.
- **Panel en tiempo real** con resumen por obra y almacén.
- Búsqueda y filtros (tipo, estado, ubicación).
- Funcionamiento básico **sin conexión** (consulta en caché y cola de movimientos pendientes).

### Fuera del MVP (roadmap)

- Panel web de administración (escritorio) — fue el boceto inicial con barra lateral.
- Etiquetas **QR** por activo para escanear y mover. *(Recomendado para v1.1.)*
- Fotos de activos y evidencias de entrega.
- Mantenimiento programado y alertas (horas de uso, próximas revisiones).
- Reportes y exportación (Excel/PDF), conteos físicos (inventario cíclico).
- Notificaciones push.
- Préstamos a terceros / subcontratistas y valorización económica del inventario.

## 5. Glosario

| Término            | Definición                                                                                     |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| **Activo**         | Bien inventariable de la constructora. Puede ser máquina o herramienta.                        |
| **Máquina**        | Activo de unidad única e identificable (trompo, taladro percutor, vibrador). Stock siempre 1.  |
| **Herramienta**    | Activo gestionado por cantidad (palas, picos, carretillas, andamios).                          |
| **Código**         | Identificador único legible: `MAQ-0007`, `HER-0142`. Se genera automáticamente.                |
| **Estado**         | Operativo, Mantenimiento o Baja.                                                               |
| **Ubicación**      | Lugar donde puede estar un activo: una **obra** o el **almacén central**.                      |
| **Obra**           | Proyecto en ejecución con nombre, dueño y ubicación geográfica.                                |
| **Almacén central**| Ubicación base desde donde se distribuyen los activos.                                         |
| **Stock**          | Cantidad de un activo en una ubicación. El stock total es la suma de todas las ubicaciones.    |
| **Movimiento**     | Traslado registrado de una cantidad de un activo desde un origen hacia un destino.             |
| **Alta**           | Ingreso de un activo nuevo al inventario (movimiento sin origen).                              |
| **Baja**           | Retiro definitivo de un activo (perdido, robado, inservible).                                  |

## 6. Reglas de negocio

| ID    | Regla                                                                                                                        |
| ----- | ---------------------------------------------------------------------------------------------------------------------------- |
| RN-01 | Una **máquina** tiene stock total **1**. Se mueve siempre con cantidad 1; no se puede dividir.                               |
| RN-02 | Una **herramienta** tiene stock por ubicación. Al moverla, el usuario indica la cantidad; máximo, lo disponible en el origen. |
| RN-03 | Origen y destino de un movimiento deben ser distintos.                                                                       |
| RN-04 | Todo movimiento registra **usuario, fecha y hora del servidor, cantidad, origen, destino** y nota opcional.                   |
| RN-05 | Los movimientos son **inmutables**. Un error se corrige con un movimiento inverso, que queda referenciado.                   |
| RN-06 | Un activo en estado **Baja** no se puede mover. Solo se consulta su historial.                                               |
| RN-07 | Un activo en **Mantenimiento** **sí puede trasladarse**; la app solo muestra un aviso antes de enviarlo a una obra (no se bloquea). |
| RN-08 | El **código** se genera automáticamente por tipo (`MAQ-`, `HER-`), es único e inmutable.                                     |
| RN-09 | Un activo con historial **no se elimina**: se da de baja.                                                                    |
| RN-10 | Una obra **cerrada** no recibe activos. Para cerrarla, su stock debe ser 0.                                                  |
| RN-11 | El **DNI** (Perú) es único por usuario y tiene exactamente **8 dígitos**.                                                    |
| RN-12 | En el MVP existe **un único almacén central**. El modelo de datos admite varios a futuro.                                    |
| RN-13 | Un usuario desactivado no puede ingresar, pero su historial se conserva.                                                     |
| RN-14 | Existen dos roles: **Administrador** y **Operador**. No hay permisos por obra: cualquier operador puede mover entre todas las obras y el almacén. Los traslados **no requieren aprobación**. |
| RN-15 | Al registrar un traslado, el operador puede **reportar una observación** (dañado, incompleto, faltante u otro) con descripción. Queda abierta y visible para el administrador hasta que la marque como atendida. |

## 7. Análisis de soluciones existentes

| Alternativa                                  | Por qué no alcanza                                                       |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| Hojas de cálculo compartidas                 | Sin trazabilidad por usuario, errores de edición, mala experiencia móvil |
| ERP de construcción (módulos de almacén)     | Costosos, complejos, pensados para oficina, sobredimensionados           |
| Apps genéricas de inventario                 | No modelan obras ni la diferencia máquina/herramienta; sin marca propia  |

**Diferencial de A2C Inventario:** diseñado para la obra (rápido, en el celular, con poca señal), con la marca de la constructora, el modelo exacto de su operación y un historial auditable.

## 8. Riesgos

| Riesgo                                                     | Prob. | Impacto | Mitigación                                                                 |
| ---------------------------------------------------------- | ----- | ------- | -------------------------------------------------------------------------- |
| Baja adopción en obra ("no tengo tiempo de registrar")     | Alta  | Alto    | Movimiento en ≤ 30 s, capacitación corta, QR en v1.1, responsables por obra |
| Señal deficiente en obra                                   | Alta  | Alto    | Caché local y cola de movimientos con reintento (RNF-OF)                    |
| Carga inicial del inventario lenta                         | Media | Alto    | Importación masiva desde Excel en Sprint 6, alta rápida por lotes          |
| Inventario de la app no coincide con la realidad           | Media | Alto    | Conteos físicos periódicos (roadmap), ajustes con motivo auditado          |
| Cambio de marca en curso (rebranding del logo)             | Alta  | Bajo    | Logo como recurso intercambiable; tokens de marca centralizados             |
| Alcance creciente (QR, fotos, reportes) antes del MVP      | Media | Medio   | Backlog posterior al MVP explícito; cambios solo entre sprints              |

## 9. Preguntas abiertas para Constructora A2C

| #  | Pregunta                                                                    | Afecta a          |
| -- | --------------------------------------------------------------------------- | ----------------- |
| P1 | Nombre definitivo: ¿"Constructora A2C" o "A2 Constructora"?                 | Marca, tiendas    |
| P2 | ~~Roles~~ → ✅ **Administrador y Operador** (2026-10-04)                      | Seguridad, UX     |
| P3 | ~~Formato del documento~~ → ✅ **DNI de Perú, 8 dígitos** (2026-10-04)        | Validaciones      |
| P4 | Volumen estimado: n.º de usuarios, obras simultáneas y activos              | Infraestructura   |
| P5 | ¿Android, iOS o ambos? ¿Celulares propios de la empresa o personales?       | Despliegue        |
| P6 | ~~Permisos por obra~~ → ✅ **No hay permisos por obra**; solo los operadores (y administradores) mueven, entre cualquier obra (2026-10-04) | Permisos |
| P7 | ¿Se necesita registrar valor económico de los activos?                      | Modelo de datos   |
| P8 | Hosting preferido y presupuesto mensual de infraestructura                  | Arquitectura      |
| P9 | ~~Activos en Mantenimiento~~ → ✅ **Se pueden trasladar con aviso, sin bloqueo** (2026-10-04) | Movimientos |
| P10 | Inventario actual en Excel (activos y cantidades por obra) para la carga inicial | Sprint 6 / piloto |
| P11 | Lista de obras activas (nombre, dueño, dirección) y de usuarios iniciales  | Semilla / piloto  |
| P12 | Cuentas de desarrollador Google Play y Apple a nombre de A2C               | Publicación       |
