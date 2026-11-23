# Mi Bolsillo (Frontend Flutter)

Aplicación móvil Flutter de finanzas personales enfocada en Colombia (**COP**), construida con **Material Design 3**, **Riverpod**, **GoRouter** e **Intl**, siguiendo el diseño de referencia en Google Stitch (*Emerald Warmth*).

> **Alcance actual:** Frontend completo, navegación, sistema visual claro/oscuro, contratos abstractos de repositorios y datos simulados en memoria (`Mock*Repository`). No incluye base de datos persistente, Firebase, backend ni lectura real de notificaciones Android.

---

## Arquitectura

```text
lib/
  app/                          # App root (MaterialApp.router) y providers de repositorios
  core/
    theme/                      # Paleta Emerald Warmth (claro/oscuro), tipografía (>=14px), espaciado
    routing/                    # Rutas y GoRouter con ShellRoute de 4 pestañas
    formatting/                 # Formateo COP en enteros ($1.250.000 COP) y fechas es_CO
    widgets/                    # Logo oficial, montos con doble codificación, estados y diálogos
  features/
    onboarding/                 # 1. Bienvenida · 2. Configuración inicial del ingreso mensual
    dashboard/                  # 3. Dashboard (Disponible = Ingreso mensual + Adicionales - Gastos)
    transactions/               # 4. Registrar gasto · 6. Movimientos (filtros, búsqueda, edición/borrado)
    income/                     # 5. Registrar ingreso adicional (snackbar tras guardar)
    budgets/                    # 10. Presupuestos (80% / Agotado) · 11. Crear presupuesto
    analysis/                   # 7. Análisis y reportes (gráfico de dona por categoría)
    automatic_detection/        # 8. Detección automática · 9. Movimientos pendientes
    profile/                    # 12. Perfil y configuración (ThemeMode claro/oscuro, reset mock)
```

---

## Requisitos previos

- **Flutter SDK estable** (probado con Flutter `3.50.1` / Dart `3.14.0`).
- **Android SDK / Emulador o dispositivo Android** (para ejecución móvil) o pruebas headless con `flutter test`.

---

## Cómo ejecutar el proyecto

1. **Clonar el repositorio y cambiar a la rama de trabajo:**
   ```bash
   git clone https://github.com/LeniSarmiento/Mi-bolsillo.git
   cd Mi-bolsillo
   git checkout feature/frontend-stitch
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar análisis estático y pruebas:**
   ```bash
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   ```

4. **Ejecutar en Android (emulador o dispositivo conectado):**
   ```bash
   flutter run
   ```

---

## Datos simulados iniciales

- **Ingreso mensual base:** `$2.400.000 COP`
- **Ingresos adicionales confirmados:** `+$480.000 COP` (`Horas extras +$180.000`, `Trabajo independiente +$300.000`)
- **Gastos:** `-$950.000 COP`
- **Disponible este mes:** `$1.930.000 COP`

---

## Seguridad y permisos

- El manifiesto principal (`android/app/src/main/AndroidManifest.xml`) **no** solicita `android.permission.INTERNET` en compilaciones release.
- No contiene claves, tokens ni secretos.
