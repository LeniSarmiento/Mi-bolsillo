# Mi Bolsillo

Aplicación Flutter de finanzas personales en pesos colombianos. El primer uso comienza con una base vacía y un formulario de ingreso mensual. Las pantallas de Stitch consumen repositorios locales mediante Riverpod. Android guarda la base SQLite en el directorio privado de la aplicación. La versión web usa SQLite con almacenamiento del navegador para el origen donde se abre.

## Ejecutar

Probado con Flutter 3.50.1 y Dart 3.14.0. Mejoras de calidad en `feature/finance-quality`:

```sh
flutter pub get
flutter run -d chrome
```

Para Android, configura el SDK y conecta un dispositivo o emulador con depuración habilitada. Usa el identificador de `flutter devices`.

```sh
flutter run -d <id-android>
flutter build apk --debug
```

El APK debug se genera en `build/app/outputs/flutter-apk/app-debug.apk`. La versión release nunca usa la clave de depuración. Para firmarla, copia `android/key.properties.example` como `android/key.properties`, crea un keystore de carga y completa sus cuatro valores. El archivo real y los keystores están excluidos de Git.

## Datos y reglas

- `lib/data/finance_database.dart` define el esquema Drift. La versión 1 contiene categorías, movimientos, presupuestos y preferencias. La migración 1 → 2 agrega una tabla de huellas de detección y la 2 → 3 agrega recibos idempotentes para alertas de presupuesto. Las instalaciones nuevas siembran las categorías de gasto, ingresos adicionales y salario.
- `lib/data/ledger.dart` contiene las operaciones de escritura, programación y consulta. Los salarios, gastos e ingresos adicionales son registros del mismo libro. Cada repositorio presenta al frontend únicamente sus tipos de movimiento. La vista de historial combina esas proyecciones.
- El disponible es un **presupuesto mensual**, no el saldo bancario ni el efectivo disponible: suma el ingreso base previsto del mes y los ingresos adicionales confirmados, y resta los gastos confirmados hasta la fecha local. La repetición del ingreso base ocurre el día 1; la frecuencia habitual de cobro es informativa y no programa depósitos. Un cambio desde Perfil afecta al mes actual y su repetición futura. Se permite 0 si no hay ingreso fijo y el historial anterior se conserva. El ingreso base no se elimina desde Movimientos.
- Los importes se guardan en columnas INTEGER. Pegar `1.250,00` registra 1250 COP; fracciones distintas de cero, valores negativos, divisas y formatos ambiguos se rechazan. La previsualización de un gasto respeta su fecha y el periodo original al editar.
- Cada movimiento recurrente conserva la próxima fecha. El inicio, la reanudación y el cambio de día en primer plano procesan las fechas vencidas. Las repeticiones son cada 7 o 14 días o por mes calendario. Si un mes carece del día original se usa su último día. La inserción y el avance de fecha comparten una transacción y la pareja plantilla-fecha es única. Desactivar una regla conserva su historial.
- Tanto en Inicio como en Movimientos, una serie ofrece **Solo este movimiento** y **Próximas repeticiones**. Editar una ocurrencia cambia exclusivamente ese registro; la programación posterior mantiene sus valores anteriores. Editar las próximas pide una primera fecha posterior a hoy, crea una plantilla futura y congela la anterior sin cambiar importes ni fechas del historial. El cambio de frecuencia no genera registros retroactivos. **Detener próximas repeticiones** cancela la plantilla futura y conserva el historial.
- Estas operaciones se ejecutan en una transacción. Los miembros históricos apuntan a la plantilla activa mediante `parent`; `scheduled` conserva el día original de una plantilla mensual para pasar por febrero sin desplazar el día 29, 30 o 31 de los siguientes meses. No se añaden columnas ni cambia el esquema 3. Una segunda escritura sobre una programación reemplazada se rechaza y requiere recargar.
- Los presupuestos semanales empiezan el lunes. Los quincenales cubren del 1 al 15 y del 16 al final del mes. El resumen mensual consolidado solo incluye los presupuestos mensuales.
- Movimientos exporta la lista filtrada a CSV y Análisis genera un PDF del periodo seleccionado. Los archivos se guardan en el destino que el usuario elige.

## Detección en Android

En **Detección automática**, la aplicación explica el acceso antes de abrir los ajustes de Android. El servicio Kotlin revisa avisos nuevos de las aplicaciones admitidas. La cola privada conserva hasta 512 candidatos con comercio, pesos, fecha, aplicación y huella. El texto completo se descarta. Se ignoran formatos ambiguos, incluidos los avisos que contienen varios montos.

El canal nativo entrega los candidatos a Flutter. SQLite guarda cada movimiento pendiente y su huella en una transacción. Solo después se acusa recibo a Android. La huella se conserva incluso al descartar o eliminar un movimiento. Editar un pendiente conserva su estado. Confirmarlo lo incorpora al saldo. Los datos financieros están excluidos del backup de Android.

La identidad normaliza mayúsculas, espacios y composición Unicode del comercio; conserva la aplicación, clave de notificación, fecha e importe para distinguir avisos diferentes. Se reconocen comercios después de «en» y «a». El canal incluye la huella anterior del mismo texto para enlazar recibos previos sin volver a importar el movimiento. Un aviso con una clave, fecha o importe diferentes sigue requiriendo revisión del usuario; no se presume que corresponde a la misma compra.

La detección depende de los avisos que emite cada aplicación y del acceso concedido en el teléfono. Compras en efectivo o avisos sin un formato reconocido requieren registro manual. En web se puede registrar y consultar dinero manualmente. Al borrar los datos del sitio se elimina su base.

Los avisos son opt-in y solo funcionan en Android. Al activar el recordatorio, la aplicación solicita el permiso de notificaciones y programa una revisión diaria aproximada a las 8 p. m. de Colombia. Las alertas de presupuesto se emiten al llegar al 80 % y al agotarse el límite, una sola vez por nivel y periodo. Todo se procesa localmente y una falla del sistema de avisos no revierte un movimiento financiero ya guardado.

## Privacidad y copias locales

El botón de ocultar montos en Inicio cubre el disponible, tarjetas, ingresos adicionales, movimientos recientes, proporciones, déficit y estimación diaria, también en las etiquetas de accesibilidad. La opción se limita a Inicio; las pantallas de edición e historial muestran los datos necesarios para operar.

En **Perfil → Copia de seguridad local** se puede exportar un JSON completo con movimientos, recurrencias, presupuestos, ajustes y recibos de deduplicación. El archivo no está cifrado: se debe elegir una carpeta privada en el dispositivo y custodiarlo. No se sincroniza automáticamente ni se habilita el backup de Android. CSV y PDF son reportes y no pueden restaurarse.

Restaurar valida formato, versión, enteros, categorías, identificadores y reglas de recurrencia antes de pedir confirmación. Rechaza dos ingresos base en el mismo mes, varias programaciones de salario activas, pendientes que no sean gastos de notificaciones y relaciones de recurrencia incompatibles. Reemplaza la base en una única transacción; ante un error de escritura se revierte íntegramente. Se bloquean las acciones de interfaz durante la operación. Detección, recordatorios y alertas quedan pausados hasta que el usuario los active. Se exporta formato 2 y se aceptan formatos 1 y 2 del esquema 3, hasta 20 MB. El formato 2 evita que versiones anteriores interpreten incorrectamente las nuevas plantillas de recurrencia.

Los cambios de Ajustes se aplican en orden para no sobrescribir preferencias recientes. Si una escritura termina y falla la recarga posterior, la pantalla permite reintentar la lectura sin informar falsamente que el guardado falló.

## Verificar y regenerar

```sh
dart format .
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

GitHub Actions repite formato, análisis, pruebas Flutter, compilación web, pruebas Kotlin y APK debug en cada rama `feature/**` y pull request.

Con el SDK Android disponible, ejecuta `gradlew.bat :app:testDebugUnitTest` desde `android` en Windows para las pruebas Kotlin del parser. Comprueba también en un dispositivo el permiso, la llegada de avisos con la app cerrada y la revocación.

Después de modificar las declaraciones de Drift, ejecuta `dart run build_runner build` y añade la migración y su prueba. La suite de Flutter ejercita los repositorios SQLite, las pantallas, la persistencia al reabrir y las migraciones desde esquemas SQL históricos v1 y v2 reales. Incluye restauración con fallo de escritura y rollback, importes pegados, edición de series, cambio de mes, confirmación en lote, permisos pendientes, privacidad y cambios concurrentes de ajustes.

Antes de distribuir una release firmada se debe probar en un teléfono Android la recepción con Flutter cerrado, revocación del permiso, reinicio del dispositivo, selectores de archivos y restauración desde una copia de prueba. Las pruebas Kotlin usan textos sintéticos: no certifican compatibilidad con todos los avisos reales de bancos o billeteras. Hace falta un keystore de producción para firmar la release; no se crea ni incluye uno en el repositorio.

Los recursos web `drift_worker.js` y `sqlite3.wasm` son los binarios de la release de Drift 2.35.4, compatibles con sqlite3 3.9.2. Se empaquetan con el proyecto. Al actualizar Drift, sustituye ambos por los recursos compatibles y comprueba sus sumas SHA-256.
