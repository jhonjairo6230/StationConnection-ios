# Registro de decisiones de arquitectura (ADR)

Un **ADR** (*Architecture Decision Record*) es una nota corta que explica una
decisión importante: qué problema había, qué se eligió, qué se descartó y qué
consecuencias tiene.

Este proyecto sigue los ADR de [DrawPad](https://github.com/jhonjairo6230/DrawPad)
que aplican a una app de radio (0001–0004 y 0006), y añade los suyos.

| N.º | Decisión | Origen | Estado |
| --- | -------- | ------ | ------ |
| [0001](0001-registrar-decisiones-con-adr.md) | Registrar las decisiones con ADR | DrawPad | Aceptada |
| [0002](0002-git-flow.md) | Usar Git Flow como flujo de ramas | DrawPad / web | Aceptada |
| [0003](0003-clean-architecture-mvvm.md) | Clean Architecture con MVVM | DrawPad | Aceptada |
| [0004](0004-compilar-sin-mac.md) | Compilar sin Mac: GitHub Actions, XcodeGen e IPA sin firmar | DrawPad | Aceptada |
| [0005](0005-avfoundation-para-reproducir.md) | AVFoundation y MediaPlayer para reproducir | Nueva (en lugar de PencilKit) | Aceptada |
| [0006](0006-documentacion.md) | Documentar con Markdown + Mermaid y comentarios DocC | DrawPad | Aceptada |
| [0007](0007-persistencia-json.md) | Guardar la biblioteca en archivos JSON | Nueva (DrawPad usa SwiftData) | Aceptada |
| [0008](0008-radio-browser-desde-la-app.md) | Llamar a Radio Browser desde la app y permitir audio por http | Nueva | Aceptada |

## Cómo añadir un ADR

1. Copia [`0000-plantilla.md`](0000-plantilla.md) con el siguiente número.
2. Rellénalo y añádelo a la tabla.
3. Un ADR aceptado **no se reescribe**: si la decisión cambia, se crea uno
   nuevo y el anterior pasa a *Reemplazada por 00NN*.
