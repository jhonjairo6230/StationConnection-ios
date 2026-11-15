# 0012. Frases de Siri que no chocan con la búsqueda de música

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** nueva (prueba en el iPhone del [ADR 0011](0011-siri-favoritas.md)).

## Contexto

Al decir "Oye Siri, pon mis favoritas en StationConnection", Siri respondió:
"No pude encontrar una lista o contenido llamado 'favoritas' en
StationConnection". El atajo sí estaba registrado: el log del CI muestra que
se entrenaron las frases en español. Pero iOS trata la forma "Pon/Reproduce
*algo* en *app*" como una petición de su búsqueda de música (SiriKit,
`INPlayMediaIntent`). Esa búsqueda tiene prioridad sobre los *App Shortcuts*.
Además, atenderla necesita el permiso de Siri, que la firma gratuita no tiene.

## Decisión

Cambiar las frases a formas que no empiecen por un verbo de reproducir
seguido de "en *app*":

- "Mis favoritas de StationConnection"
- "Mis favoritas en StationConnection"
- "StationConnection mis favoritas"
- "Favoritas de StationConnection"
- "Radio favorita de StationConnection"

El intent y su comportamiento no cambian.

## Alternativas consideradas

- **Atender `INPlayMediaIntent` (SiriKit):** permitiría decir "pon…", pero
  necesita el permiso `com.apple.developer.siri`, que las cuentas gratuitas
  no tienen.
- **Pedir al usuario que cree un atajo propio en la app Atajos:** funciona con
  cualquier frase, pero obliga a configurarlo a mano. Queda documentado como
  respaldo.

## Consecuencias

- Las frases de "pon…" del ADR 0011 dejan de usarse.
- Si alguna frase sigue sin reconocerse, el respaldo es crear un atajo en la app
  Atajos con la acción "Mis favoritas" de StationConnection y llamarlo como se
  quiera (por ejemplo, "Radio"). Se ejecuta con "Oye Siri, Radio".
