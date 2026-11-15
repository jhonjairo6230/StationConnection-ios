# 0001. Registrar las decisiones con ADR

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** misma decisión que el ADR 0001 de [DrawPad](https://github.com/jhonjairo6230/DrawPad).

## Contexto

StationConnection-ios es la versión nativa para iPhone y iPad de la app web
[StationConnection](https://github.com/jhonjairo6230/StationConnection). Se
desarrolla con ayuda de un asistente de IA y se quiere poder volver a ella
meses después y entender **por qué** el código es como es.

## Decisión

Cada decisión de arquitectura o de proceso se escribe como un ADR corto en
`docs/adr/`, numerado y en español, con la [plantilla](0000-plantilla.md):
contexto, decisión, alternativas y consecuencias. Las decisiones que vienen de
DrawPad lo indican en el campo **Origen**.

## Alternativas consideradas

- **Explicarlo todo en el README:** crece sin orden y mezcla el "cómo se usa"
  con el "por qué se hizo así".
- **Mensajes de commit o pull requests:** se pierden en el historial.
- **Wiki de GitHub:** queda fuera del repo y no se versiona con el código.

## Consecuencias

- Cada decisión se lee en dos minutos, con sus alternativas.
- Hay que acordarse de escribir un ADR cuando se decide algo importante.
- Los ADR aceptados no se reescriben: si algo cambia, se añade uno nuevo que
  reemplaza al anterior.
