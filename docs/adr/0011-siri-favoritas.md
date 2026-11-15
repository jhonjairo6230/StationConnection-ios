# 0011. Poner las favoritas con Siri

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** nueva (pedido del autor: abrir las favoritas con Siri, sobre todo en el auto).

## Contexto

Con firma gratuita la app no sale en la lista de CarPlay ([ADR 0009](0009-carplay.md)),
pero Siri sí funciona en el auto. Los *App Shortcuts* (App Intents) no
necesitan ningún permiso especial: iOS los registra al instalar la app, sin
que el usuario tenga que configurar nada.

## Decisión

- `PlayFavoritesIntent` (`AudioPlaybackIntent`) con las frases de
  `StationShortcuts`. Por ejemplo, "Pon mis favoritas en StationConnection".
  La radio suena sin abrir la app en pantalla.
- Usa el mismo puente que los widgets (`WidgetPlaybackBridge`, [ADR 0010](0010-widgets.md))
  y `WidgetPlaybackActions.playFavorites()`: empieza por la primera favorita y
  deja las demás como cola de ⏮/⏭ (del volante también).
- Sin favoritas, Siri responde cómo marcarlas.
- El idioma base del proyecto pasa a español (`developmentLanguage: es`) para
  que Siri reconozca las frases en español.

## Alternativas consideradas

- **Elegir una emisora por nombre ("pon La Mega"):** necesita una consulta
  de entidades (`AppEntity`) y solo reconoce nombres conocidos. Se deja para
  más adelante; el autor pidió solo las favoritas.
- **SiriKit (`INPlayMediaIntent`):** API antigua, más código y su propio
  permiso.

## Consecuencias

- Funciona con Sideloadly y en CarPlay por voz.
- Siri puede tardar unos minutos en aprender las frases después de instalar
  o actualizar la app. El atajo también aparece en la app Atajos.
- Si la app está cerrada, iOS la abre en segundo plano: la primera vez puede
  tardar un momento.
