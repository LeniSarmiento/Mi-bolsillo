# Mi Bolsillo

Aplicación Flutter de finanzas personales en pesos colombianos. El primer uso comienza con una base vacía y un formulario de ingreso mensual. Las pantallas de Stitch consumen repositorios locales mediante Riverpod. Android guarda la base SQLite en el directorio privado de la aplicación. La versión web usa SQLite con almacenamiento del navegador para el origen donde se abre.

## Ejecutar

Probado con Flutter 3.50.1 y Dart 3.14.0. Desde la rama `feature/core-finance`:

```sh
flutter pub get
flutter run -d chrome
```

Para Android, configura el SDK y conecta un dispositivo o emulador con depuración habilitada. Usa el identificador de `flutter devices`.

```sh
flutter run -d <id-android>
flutter build apk --debug
```

El APK debug se genera en `build/app/outputs/flutter-apk/app-debug.apk`. Para distribuir una release configura una firma propia. La plantilla actual referencia la clave de depuración.

## Datos y reglas

- `lib/data/finance_database.dart` define el esquema Drift. La versión 1 contiene categorías, movimientos, presupuestos y preferencias. La migración 1 → 2 agrega una tabla de huellas de notificaciones. Las instalaciones nuevas siembran las categorías de gasto, ingresos adicionales y salario.
- `lib/data/ledger.dart` contiene las operaciones de escritura, programación y consulta. Los salarios, gastos e ingresos adicionales son registros del mismo libro. Cada repositorio presenta al frontend únicamente sus tipos de movimiento. La vista de historial combina esas proyecciones.
- El disponible suma el salario del mes y los ingresos adicionales confirmados, y resta los gastos confirmados hasta la fecha local. Un cambio de salario afecta al mes en edición y su repetición futura. Los importes se guardan en columnas INTEGER.
- Cada movimiento recurrente conserva la próxima fecha. El inicio, la reanudación y el cambio de día en primer plano procesan las fechas vencidas. Las repeticiones son cada 7 o 14 días o por mes calendario. Si un mes carece del día original se usa su último día. La inserción y el avance de fecha comparten una transacción y la pareja plantilla-fecha es única. Desactivar una regla conserva su historial.
- Los presupuestos semanales empiezan el lunes. Los quincenales cubren del 1 al 15 y del 16 al final del mes. El resumen mensual consolidado solo incluye los presupuestos mensuales.
- Movimientos exporta la lista filtrada a CSV y Análisis genera un PDF del periodo seleccionado. Los archivos se guardan en el destino que el usuario elige.

## Detección en Android

En **Detección automática**, la aplicación explica el acceso antes de abrir los ajustes de Android. El servicio Kotlin revisa avisos nuevos de las aplicaciones admitidas. La cola privada conserva hasta 512 candidatos con comercio, pesos, fecha, aplicación y huella. El texto completo se descarta. Se ignoran formatos ambiguos, incluidos los avisos que contienen varios montos.

El canal nativo entrega los candidatos a Flutter. SQLite guarda cada movimiento pendiente y su huella en una transacción. Solo después se acusa recibo a Android. La huella se conserva incluso al descartar o eliminar un movimiento. Editar un pendiente conserva su estado. Confirmarlo lo incorpora al saldo. Los datos financieros están excluidos del backup de Android.

La detección depende de los avisos que emite cada aplicación y del acceso concedido en el teléfono. Compras en efectivo o avisos sin un formato reconocido requieren registro manual. En web se puede registrar y consultar dinero manualmente. Al borrar los datos del sitio se elimina su base. La preferencia de recordatorio diario se guarda, pero esta versión aún no programa avisos a las 8 p. m.

## Verificar y regenerar

```sh
dart format .
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Con el SDK Android disponible, ejecuta `gradlew.bat :app:testDebugUnitTest` desde `android` en Windows para las pruebas Kotlin del parser. Comprueba también en un dispositivo el permiso, la llegada de avisos con la app cerrada y la revocación.

Después de modificar las declaraciones de Drift, ejecuta `dart run build_runner build` y añade la migración y su prueba. La suite de Flutter ejercita los repositorios SQLite, las pantallas, la persistencia al reabrir y la migración conservando datos.

Los recursos web `drift_worker.js` y `sqlite3.wasm` son los binarios de la release de Drift 2.35.4, compatibles con sqlite3 3.9.2. Se empaquetan con el proyecto. Al actualizar Drift, sustituye ambos por los recursos compatibles y comprueba sus sumas SHA-256.
