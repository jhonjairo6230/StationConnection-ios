# 0014. Encontrar el App Group de la firma y detectar las pausas del sistema

- **Estado:** Aceptada
- **Fecha:** 2026-11-23
- **Origen:** nueva (prueba en el iPhone y en CarPlay del [ADR 0013](0013-widgets-configurables.md)).

## Contexto

En el iPhone y en CarPlay, el widget "Sonando" ponía la radio, pero:

- **No mostraba qué emisora sonaba** ni su carátula. Seguía en el modo de
  respaldo: "▶ retoma tu última emisora".
- ▶ seguía siendo ▶ mientras sonaba, y eso confunde. Se espera que pase a ■.
- **A veces había que tocar ■ y luego ▶** para que volviera a sonar.

Causas:

1. La app buscaba el App Group solo con el nombre fijo de `project.yml`. Los
   firmadores como Sideloadly suelen registrar el grupo con **otro nombre**
   (por ejemplo, con el identificador del equipo al final). Ese otro nombre
   queda en el perfil de firma que incrustan en la app
   (`embedded.mobileprovision`).
2. `AVFoundationAudioPlayer` ignoraba la pausa de `AVPlayer`. Cuando iOS
   pausa el audio por su cuenta (al conectar CarPlay, Siri, una llamada, otra
   app), la app seguía creyendo que sonaba. Por eso ▶ no hacía nada hasta
   tocar ■.

## Decisión

- `SharedWidgetStore.live()` prueba los App Groups en este orden:
  1. El de `project.yml`.
  2. Los del perfil incrustado que mencionan "stationconnection".
  3. El resto del perfil.

  Dentro de cada bloque, el orden es alfabético, así que la app y la
  extensión llegan al mismo grupo. Usa el primero que iOS deja abrir
  (`containerURL`).
- Si no abre ninguno, `diagnostic` dice por qué:
  - "Sin perfil de firma"
  - "La firma no trae App Group"
  - "iOS no abre el App Group de la firma"

  El widget muestra el motivo en letra pequeña en su modo de respaldo, para
  saber qué pasa sin un Mac.
- **Con App Group**, el widget sabe si suena: muestra la emisora, su carátula
  y **un solo botón que cambia entre ▶ y ■**. En los widgets configurables,
  la emisora que suena se resalta y su botón pasa a ■.
- **Sin App Group** se queda como antes: ▶ y ■ separados.
- Nuevo `AudioPlayerState.interrupted`. Lo emite `AVFoundationAudioPlayer`
  cuando `AVPlayer` queda en pausa sin que la app lo pidiera; lee el estado
  actual para no confundirse con avisos viejos. `PlayerViewModel` deja la
  emisora detenida (`.stopped`), así que ▶ (de la app, el widget o el
  volante) la vuelve a poner en directo.

## Alternativas consideradas

- **Reanudar solo al terminar la interrupción:** en radio en vivo, retomar lo
  que había en el búfer suena con retraso. Además, el usuario puede no querer
  que vuelva a sonar (por ejemplo, tras una llamada).
- **Leer los permisos del binario (`SecTask`):** no es una API pública en iOS.

## Consecuencias

- Si Sideloadly registra el grupo, el widget muestra la emisora y el botón
  cambia de ▶ a ■, también en CarPlay.
- Si la cuenta gratuita no permite App Groups, el widget lo dice
  ("La firma no trae App Group"). En ese caso siguen los widgets configurables
  del ADR 0013.
- Quitar los auriculares o una llamada dejan la radio detenida en vez de
  "sonando" en silencio.
