# 0010. Widgets para el teléfono y el auto

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** nueva (pedido del autor: "un widget para teléfono y para carro").

## Contexto

Se quiere controlar la radio sin abrir la app: desde la pantalla de inicio,
la pantalla de bloqueo y la pantalla del auto. Hay que tener en cuenta lo
siguiente:

- Un widget es una **extensión aparte**, con su propio proceso. No tiene red
  ni reproductor, y solo se redibuja cuando iOS lo decide o la app se lo pide
  (con un cupo diario).
- Desde **iOS 26**, CarPlay muestra los widgets `systemSmall` del iPhone **sin
  necesitar el permiso de CarPlay** ([ADR 0009](0009-carplay.md)). Es la única
  forma de tener algo de la app en la pantalla del auto con la firma gratuita.
- Los botones de un widget son *App Intents*. Los que adoptan
  `AudioPlaybackIntent` se ejecutan **dentro de la app**, que iOS abre en
  segundo plano si hace falta. Ahí vive el reproductor.
- Para que el widget sepa qué suena, la app debe dejarle los datos en un
  **App Group** (un contenedor compartido). Sideloadly con Apple ID gratuito
  puede no incluirlo en la firma.

## Decisión

- Nueva extensión **`StationConnectionWidgets`** (`project.yml`, tipo
  `app-extension`) con dos widgets:
  - **Sonando**: `systemSmall` (inicio y CarPlay), `accessoryCircular` y
    `accessoryRectangular` (pantalla de bloqueo). Muestra la emisora, la
    canción y un botón ▶/■.
  - **Favoritas**: `systemMedium`. Muestra lo que suena y cuatro favoritas
    que se ponen a sonar con un toque.
- Carpeta **`Shared/`**, que compilan los dos *targets*:
  - `WidgetSnapshot`: la "foto" que pinta el widget.
  - `SharedWidgetStore`: guarda la foto en el App Group.
  - `PlayStationIntent` y `TogglePlaybackIntent` (`AudioPlaybackIntent`),
    con un puente `WidgetPlaybackBridge` que la app rellena al arrancar.
- En la app, `Presentation/Widgets/`:
  - `WidgetSync` observa el reproductor y la biblioteca, y publica la foto
    solo si cambió, para no gastar el cupo de redibujado.
  - `WidgetPlaybackActions` decide qué hacer con cada botón.
- `AppContainer.registerWidgetActions()` se llama en el `init` de la app, antes
  de cualquier pantalla, porque iOS puede abrirla en segundo plano solo para
  ejecutar un botón.
- **Degradación sin App Group:** `SharedWidgetStore.live()` comprueba el
  contenedor. Si no existe, la app no publica nada y el widget muestra un
  texto de respaldo. Los botones siguen funcionando, porque no necesitan el
  App Group.
- Las carátulas del widget son iniciales sobre el degradado de la emisora: un
  widget no descarga logos.

## Alternativas consideradas

- **Live Activity / Dynamic Island:** pensadas para eventos con fin (un
  pedido, un partido). La radio ya aparece en "Reproduciendo".
- **Widget configurable (elegir emisora):** necesita
  `AppIntentConfiguration` y una consulta de entidades. Se deja para más
  adelante; cuatro favoritas cubren el uso habitual.
- **Abrir la app con un enlace (`widgetURL`):** obliga a desbloquear y a
  mostrar la app. Con `AudioPlaybackIntent` suena sin salir del widget.

## Consecuencias

- **CarPlay:** el widget aparece en el auto solo con **iOS 26 o posterior**.
  En versiones anteriores sigue funcionando en el teléfono.
- **Firma gratuita:** Sideloadly firma la extensión con un segundo
  identificador (`….widgets`). Los Apple ID gratuitos tienen un límite de
  identificadores por semana. Si el App Group no queda en la firma, el widget
  muestra el texto de respaldo, pero ▶/■ y las favoritas siguen sonando.
- La primera vez que se toca un botón con la app cerrada, iOS tarda un
  momento en abrirla en segundo plano. A veces el primer toque no hace nada.
- La lógica (foto, sincronización, botones) tiene pruebas. Las vistas del
  widget se verifican a mano en el iPhone.
