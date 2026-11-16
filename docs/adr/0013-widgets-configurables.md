# 0013. Widgets configurables que no dependen del App Group

- **Estado:** Aceptada
- **Fecha:** 2026-11-16
- **Origen:** nueva (prueba en el iPhone del [ADR 0010](0010-widgets.md)).

## Contexto

Al instalar con Sideloadly y un Apple ID gratuito:

- La firma **no incluye el App Group**. Los widgets se quedan en su modo de
  respaldo: no ven qué suena ni las favoritas, ni en el teléfono ni en CarPlay.
- "Editar widget" no aparece porque los widgets usan `StaticConfiguration`.
- El botón único ▶/■ siempre mostraba ▶, porque sin datos compartidos el
  widget no sabe si la radio suena. Al tocarlo con la radio sonando, la
  detenía y **volvía a cargar**. La causa más probable: después de un
  `AudioPlaybackIntent`, iOS manda por su cuenta la orden "reproducir"
  (`MPRemoteCommandCenter`) a la app que sonaba. También es posible que el
  mismo toque llegue dos veces.
- Los intents sí llegan a la app: el atajo "Mis favoritas" de la app Atajos
  funciona.

## Decisión

- **Widgets configurables** (`AppIntentConfiguration`):
  - **"Mi emisora"** (`systemSmall`): inicio y **CarPlay** (iOS 26+).
  - **"Mis emisoras"** (`systemMedium`): hasta cuatro emisoras.
  - El usuario elige las emisoras en "Editar widget".
  - El selector (`RadioStationQuery`) busca en Radio Browser **desde la
    extensión** (`RadioBrowserLookup`). Guarda lo que encuentra en la caché
    propia de la extensión, así que no necesita el App Group.
  - Al tocar una emisora, la app la busca por id y la pone (`PlayStationIntent`).
- **▶ y ■ separados** (`ResumePlaybackIntent`, `StopPlaybackIntent`) en los
  widgets de inicio. Cada botón hace lo que dice, sepa o no el widget qué
  suena. El botón único ▶/■ queda solo en el círculo de la pantalla de
  bloqueo.
- **Acciones idempotentes** (`WidgetPlaybackActions`):
  - ▶ no reinicia una emisora que ya suena.
  - Tocar la emisora que ya suena no la reinicia.
  - Un ▶/■ repetido dentro de un segundo se ignora.
- **■ desde un widget o atajo** (`PlayerViewModel.stopFromShortcut`): durante
  3 segundos se ignora el "reproducir" del sistema. Una reproducción
  explícita quita el bloqueo.
- Las iniciales y el degradado de la carátula pasan a `Shared/StationArtworkText`,
  para que la app y los widgets configurables coincidan.

## Alternativas consideradas

- **Compartir datos por el llavero (Keychain) en vez del App Group:** también
  necesita un permiso en la firma (grupo de acceso) que depende de lo que
  haga Sideloadly.
- **Que el widget lea las favoritas por red:** las favoritas solo existen en
  el iPhone; no hay servidor.

## Consecuencias

- Con la firma gratuita el widget sí muestra emisoras y funciona en CarPlay,
  pero hay que elegirlas en "Editar widget". No se sincronizan con las
  favoritas de la app.
- El widget no muestra qué suena. Eso ya se ve en la isla dinámica, la
  pantalla de bloqueo y "Reproduciendo" de CarPlay.
- "Sonando" y "Favoritas" (ADR 0010) siguen igual: con una firma que incluya
  el App Group muestran el estado real.
- Abrir el selector necesita internet. Pintar el widget no, porque las
  emisoras elegidas quedan guardadas en la configuración y en la caché.
