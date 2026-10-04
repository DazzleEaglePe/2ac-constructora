# 02 — Requerimientos Funcionales

> **Priorización MoSCoW:** **M** = Must (MVP) · **S** = Should (MVP si alcanza) · **C** = Could (post-MVP) · **W** = Won't (fuera de alcance por ahora)
> **Sprint:** sprint del plan ([`10_PLAN_DESARROLLO.md`](./10_PLAN_DESARROLLO.md)) en que se implementa.

---

## 1. Módulos

| Código | Módulo                     | Descripción                                               |
| ------ | -------------------------- | --------------------------------------------------------- |
| BIE    | Bienvenida                 | Splash animado, onboarding                                 |
| AUT    | Autenticación              | Ingreso, sesión, cierre de sesión                          |
| USR    | Usuarios                   | Gestión de cuentas y roles                                 |
| UBI    | Obras y almacén            | Ubicaciones donde viven los activos                        |
| ACT    | Activos                    | Catálogo de máquinas y herramientas                        |
| MOV    | Movimientos                | Mover, asignar, alta, baja e historial                     |
| PAN    | Panel en tiempo real       | Resumen del inventario y actualizaciones en vivo           |
| BUS    | Búsqueda y filtros         | Encontrar activos y obras                                  |
| OFF    | Sin conexión               | Caché y cola de operaciones pendientes                     |
| AUD    | Auditoría                  | Registro de acciones administrativas                       |

---

## 2. Bienvenida (BIE)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-BIE-01  | Al abrir la app se muestra el **splash con la animación del logo A2C** (ver `09_DESIGN_SYSTEM.md` §8).            | M         | 1      |
| RF-BIE-02  | Si el usuario tiene sesión válida, tras el splash entra directo al panel; si no, va al onboarding o al ingreso.  | M         | 1      |
| RF-BIE-03  | En el primer uso se muestra el **onboarding de 3 pasos** (Ubicación, Movimientos, Control) con "Saltar".         | M         | 1      |
| RF-BIE-04  | El onboarding no se vuelve a mostrar después de completarlo o saltarlo (se recuerda en el dispositivo).          | M         | 1      |
| RF-BIE-05  | Si el sistema tiene activado "reducir movimiento", el splash muestra el logo final sin animación.               | S         | 1      |

## 3. Autenticación (AUT)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-AUT-01  | El usuario ingresa con **DNI y contraseña**.                                                                     | M         | 1      |
| RF-AUT-02  | La sesión se mantiene entre aperturas de la app hasta que expire o el usuario salga.                             | M         | 1      |
| RF-AUT-03  | El usuario puede **cerrar sesión** desde el panel.                                                               | M         | 1      |
| RF-AUT-04  | Tras 5 intentos fallidos, la cuenta se bloquea 15 minutos y se informa al usuario.                               | M         | 1      |
| RF-AUT-05  | En el primer ingreso con contraseña temporal, el usuario debe definir una contraseña nueva.                      | M         | 1      |
| RF-AUT-06  | "¿Olvidaste tu contraseña?" indica contactar al administrador, quien puede restablecerla.                        | M         | 1      |
| RF-AUT-07  | Desbloqueo con biometría (huella / Face ID) para reabrir la app con sesión activa.                               | C         | —      |

**Criterios de aceptación (RF-AUT-01):**
- Dado un DNI y contraseña válidos, cuando toco "Ingresar", entonces veo el panel en menos de 2 s con buena conexión.
- Dado un DNI o contraseña incorrectos, entonces veo "DNI o contraseña incorrectos" (sin revelar cuál falló).
- Dado un usuario desactivado, entonces veo "Tu cuenta está desactivada. Contacta al administrador."

## 4. Usuarios (USR)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-USR-01  | El administrador ve la lista de usuarios con nombre, DNI, rol, estado y último movimiento.                       | M         | 1      |
| RF-USR-02  | El administrador crea usuarios con **DNI (8 dígitos), nombre completo, rol (Administrador u Operador) y contraseña temporal**. | M | 1  |
| RF-USR-03  | El administrador edita nombre y rol de un usuario.                                                               | M         | 1      |
| RF-USR-04  | El administrador **desactiva y reactiva** usuarios (no se eliminan).                                             | M         | 1      |
| RF-USR-05  | El administrador **restablece la contraseña** de un usuario (genera una temporal).                               | M         | 1      |
| ~~RF-USR-06~~ | ~~Asignar obras a un usuario~~ — **descartado**: no hay permisos por obra (decisión 2026-10-04, RN-14).        | —         | —      |
| RF-USR-07  | Cada usuario puede ver y cambiar su propia contraseña.                                                           | S         | 1      |

## 5. Obras y almacén (UBI)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-UBI-01  | Crear una obra con **nombre, dueño y ubicación** (dirección + punto en el mapa).                                 | M         | 2      |
| RF-UBI-02  | Editar los datos de una obra.                                                                                    | M         | 2      |
| RF-UBI-03  | Ver el detalle de una obra: dueño, mapa, "Abrir en Maps", unidades y lista de activos con cantidades y estado.   | M         | 2      |
| RF-UBI-04  | Filtrar los activos de una obra por tipo (Todos, Máquinas, Herramientas).                                        | M         | 2      |
| RF-UBI-05  | **Cerrar** una obra (solo si su stock es 0, RN-10) y reabrirla.                                                  | S         | 2      |
| RF-UBI-06  | Existe un **Almacén central** creado en la configuración inicial; se ve como una ubicación más.                  | M         | 2      |
| RF-UBI-07  | Buscar una dirección y ajustar el pin en el mapa al crear la obra.                                               | S         | 2      |

## 6. Activos (ACT)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-ACT-01  | Registrar un activo con **tipo (máquina/herramienta), nombre, descripción, estado, stock inicial y ubicación inicial**. | M   | 3      |
| RF-ACT-02  | El **código** se genera automáticamente según el tipo (RN-08) y se muestra antes de guardar.                     | M         | 3      |
| RF-ACT-03  | Si el tipo es máquina, el stock queda fijo en 1 (RN-01) y la interfaz lo explica.                                | M         | 3      |
| RF-ACT-04  | Editar nombre y descripción de un activo.                                                                        | M         | 3      |
| RF-ACT-05  | Cambiar el **estado** (Operativo, Mantenimiento, Baja) con motivo obligatorio para Baja.                         | M         | 3      |
| RF-ACT-06  | Ver el detalle: código, tipo, estado, descripción, stock total, **distribución por ubicación** e historial.     | M         | 3      |
| RF-ACT-07  | Agregar y ver **notas** de un activo (texto, autor, fecha).                                                      | M         | 3      |
| RF-ACT-08  | Listado general de inventario con stock total y número de ubicaciones por activo.                                | M         | 3      |
| RF-ACT-09  | Importación masiva desde plantilla Excel/CSV para la carga inicial.                                              | S         | 6      |
| RF-ACT-10  | Foto del activo.                                                                                                 | C         | —      |
| RF-ACT-11  | Generar e imprimir etiqueta **QR** por activo; escanear el QR abre su detalle.                                   | C         | —      |

## 7. Movimientos (MOV)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-MOV-01  | **Mover o asignar** un activo eligiendo **origen** (con disponibles), **destino** y **cantidad**.                | M         | 4      |
| RF-MOV-02  | Para herramientas, la cantidad va de 1 a lo disponible en el origen (RN-02); para máquinas es 1 fija (RN-01).    | M         | 4      |
| RF-MOV-03  | El destino no puede ser igual al origen (RN-03) ni una obra cerrada (RN-10).                                     | M         | 4      |
| RF-MOV-04  | Antes de confirmar se muestra un resumen: "Mover N unidades de X a Y" y "Queda registrado a nombre de …".        | M         | 4      |
| RF-MOV-05  | Al confirmar, el stock de origen y destino se actualiza **atómicamente** y se crea el registro inmutable (RN-04/05). | M     | 4      |
| RF-MOV-06  | Nota opcional en cada movimiento.                                                                                | M         | 4      |
| RF-MOV-07  | Historial de movimientos **por activo** (más reciente primero): origen → destino, cantidad, usuario, fecha, nota. | M        | 4      |
| RF-MOV-08  | Historial de movimientos **por obra** y general, con filtros por fecha y usuario.                                | S         | 4      |
| RF-MOV-09  | **Revertir** un movimiento creando el movimiento inverso referenciado (solo admin/almacenero).                    | S         | 4      |
| RF-MOV-10  | Atajo "Asignar activo a esta obra" desde el detalle de la obra (destino precargado).                             | M         | 4      |
| RF-MOV-11  | Aviso (no bloqueante) al enviar a obra un activo en Mantenimiento; el traslado se permite (RN-07).              | M         | 4      |
| RF-MOV-12  | Confirmación visual del movimiento (pantalla/tostada "Movimiento registrado").                                   | M         | 4      |
| RF-MOV-13  | Al mover, el operador puede **reportar una observación** (Dañado, Incompleto, Faltante, Otro) con descripción (RN-15). El movimiento se registra igual, sin aprobación. | M | 4 |
| RF-MOV-14  | El historial y el detalle del activo muestran las observaciones con su estado (abierta / atendida).              | M         | 4      |

**Criterios de aceptación (RF-MOV-05):**
- Dado un origen con 2 unidades, cuando dos usuarios intentan mover 2 unidades a la vez, entonces solo uno tiene éxito y el otro recibe "Stock insuficiente en el origen".
- Dado un movimiento confirmado, entonces el stock total del activo no cambia (solo se redistribuye).
- Dado un movimiento confirmado, entonces aparece al instante en el historial y en el panel de los demás usuarios.

## 8. Panel en tiempo real (PAN)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-PAN-01  | Panel principal con resumen: **unidades en obra, activos en mantenimiento, obras activas**.                      | M         | 5      |
| RF-PAN-02  | Tarjeta por obra: nombre, dirección, principales activos (chips con cantidad), dueño, unidades y último movimiento. | M      | 5      |
| RF-PAN-03  | Tarjeta del **Almacén central** con unidades disponibles para asignar.                                            | M         | 5      |
| RF-PAN-04  | Indicador **"En vivo · actualizado hace N s"**; los cambios de otros usuarios se reflejan sin recargar (≤ 2 s).    | M         | 5      |
| RF-PAN-05  | Accesos rápidos: "+ Herramienta o equipo", "+ Obra", "Mover activo".                                              | M         | 5      |
| RF-PAN-06  | Deslizar hacia abajo para refrescar.                                                                              | M         | 5      |
| RF-PAN-07  | El administrador ve **Observaciones abiertas** en el panel (activo, tipo, descripción, operador, fecha) y las marca como atendidas con un comentario. | M | 5 |

## 9. Búsqueda y filtros (BUS)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-BUS-01  | Buscar activos por **nombre o código** desde el panel y el inventario.                                            | M         | 3      |
| RF-BUS-02  | Filtrar inventario por **tipo** y por **estado**.                                                                 | M         | 3      |
| RF-BUS-03  | Buscar obras por nombre o dueño.                                                                                  | S         | 2      |
| RF-BUS-04  | Estado vacío "Sin resultados" con opción de limpiar filtros.                                                      | M         | 3      |
| RF-BUS-05  | **Consultar disponibilidad:** al buscar una herramienta o máquina, cada resultado muestra **en qué obras y en el almacén está y cuántas unidades hay**, sin entrar al detalle. Reemplaza las llamadas entre obras. | M | 3 |

**Criterios de aceptación (RF-BUS-05):**
- Dado que busco "pala", entonces veo "Pala de punta · 8 uds" con "Almacén central 6 · Obra Juan Ramírez 2" en el mismo resultado.
- Dado un activo en Baja, entonces aparece marcado como no disponible.
- La respuesta llega en ≤ 1 s con buena conexión, y sin conexión muestra los datos en caché con su antigüedad.

## 10. Sin conexión (OFF)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-OFF-01  | Sin conexión, la app muestra los últimos datos descargados con un aviso "Sin conexión · datos de hace N min".    | M         | 6      |
| RF-OFF-02  | Un movimiento hecho sin conexión queda **pendiente** y se envía automáticamente al volver la señal.               | S         | 6      |
| RF-OFF-03  | Si un movimiento pendiente es rechazado (p. ej., stock insuficiente), el usuario recibe el motivo y puede corregirlo. | S     | 6      |
| RF-OFF-04  | Las altas de activos, obras y usuarios requieren conexión.                                                        | M         | 6      |

## 11. Auditoría (AUD)

| ID         | Requerimiento                                                                                                   | Prioridad | Sprint |
| ---------- | --------------------------------------------------------------------------------------------------------------- | --------- | ------ |
| RF-AUD-01  | Se registran las acciones administrativas: alta/edición/desactivación de usuarios, cambios de estado, cierre de obras, reversiones. | M | 5 |
| RF-AUD-02  | El administrador puede consultar el registro de auditoría filtrado por usuario, acción y fecha.                   | S         | 5      |

---

## 12. Resumen de cobertura

| Prioridad | Cantidad | En el MVP |
| --------- | -------- | --------- |
| Must      | 54       | Sí        |
| Should    | 11       | Si alcanza el sprint |
| Could     | 3        | No        |

> Trazabilidad: cada requerimiento aparece en la checklist del sprint correspondiente en `10_PLAN_DESARROLLO.md`.
