# Prompt para Antigravity — integración UI final de Mi Bolsillo

Trabaja sobre el frontend Flutter aprobado de **Mi Bolsillo** usando como base la rama que ya contiene la persistencia y las reglas financieras reales.

## Repositorio y rama

Repositorio:

`https://github.com/LeniSarmiento/Mi-bolsillo.git`

Ejecuta primero:

```bash
git fetch origin
git switch -c feature/ui-integration origin/feature/core-hardening
flutter pub get
flutter analyze
flutter test
```

Publica tu trabajo en:

`feature/ui-integration`

No trabajes en `feature/frontend-stitch`, `feature/core-finance`, `feature/core-hardening` ni `main`. No fusiones ramas.

## Contexto

Las pantallas diseñadas en Stitch ya fueron aprobadas. La rama base incorpora SQLite con Drift, repositorios reales, ingresos, gastos, salario mensual, recurrencias, presupuestos, análisis, exportaciones, detección Android y estados `isLoading`, `isSaving`, `isDeleting` y `errorMessage` en los controladores correspondientes.

Conserva la identidad visual, navegación, colores, tipografía, espaciado, logo y componentes existentes. Tu tarea es revisar y terminar la integración visual de los estados reales.

## Archivos reservados para Codex

No modifiques:

- `lib/data/**`
- `lib/app/providers.dart`
- `lib/main.dart`
- `lib/features/**/domain/**`
- `lib/features/**/application/**`
- `android/**`
- `.github/**`
- `pubspec.yaml`
- `pubspec.lock`

Si una corrección visual parece necesitar uno de esos archivos, documenta el caso en tu entrega y continúa con el resto.

## Trabajo solicitado

Revisa estas pantallas con los datos reales de `feature/core-finance`:

1. Bienvenida y configuración inicial.
2. Dashboard.
3. Registrar y editar gasto.
4. Registrar y editar ingreso adicional.
5. Movimientos y filtros.
6. Análisis.
7. Presupuestos y edición de presupuesto.
8. Detección automática.
9. Movimientos pendientes.
10. Perfil y configuración.

Comprueba y corrige únicamente en la capa de presentación:

- Estados `loading`, vacío, datos y error.
- Estados de guardado y botones deshabilitados para evitar doble envío.
- Mensajes de éxito después de guardar.
- Confirmaciones antes de eliminar o descartar.
- Desbordamientos en 320, 360, 412, 600 y 1024 px de ancho.
- Teclado abierto, desplazamiento y campos que deben permanecer visibles.
- Modo claro y oscuro.
- Contraste, tamaño mínimo de texto y áreas táctiles.
- Lectura mediante accesibilidad y etiquetas de iconos.
- Montos largos, saldo negativo y categorías sin movimientos.
- Textos de privacidad consistentes con almacenamiento local.
- En web, indicar claramente que la detección automática está disponible en Android.

## Restricciones de contenido

No muestres ni afirmes:

- Conexión directa con bancos.
- Sincronización en la nube.
- Cifrado total o seguridad absoluta.
- Detección mediante SMS.
- Datos simulados en la experiencia normal.

Puedes mostrar:

`La información se procesa y almacena localmente en tu dispositivo.`

## Pruebas

Conserva las pruebas existentes. Añade pruebas de widgets solo para correcciones visuales o regresiones concretas que realices.

Antes de entregar ejecuta:

```bash
dart format .
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Prueba manualmente la vista web y documenta los anchos revisados. No introduzcas datos Mock en producción.

## Entrega

Realiza commits pequeños y descriptivos. Sube `feature/ui-integration` y entrega:

- Resumen de pantallas revisadas.
- Archivos modificados.
- Problemas visuales corregidos.
- Pruebas ejecutadas y resultados.
- Casos que requieran cambios en archivos reservados.
- URL de la rama publicada.

No abras ni fusiones un pull request sin aprobación del propietario.
