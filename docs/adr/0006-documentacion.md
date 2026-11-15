# 0006. Documentar con Markdown + Mermaid y comentarios DocC

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** ADR 0006 de DrawPad (se aplica igual).

## Contexto

La documentación tiene que leerse **desde Windows y desde GitHub**, sin
Xcode, e incluir diagramas.

## Decisión

1. **En el código:** comentarios `///` con sintaxis DocC en cada tipo y en
   los métodos que lo merecen. Explican el **porqué**.
2. **En `docs/`:** Markdown con diagramas **Mermaid** (GitHub los dibuja):
   - `arquitectura.md`: capas, clases y secuencias.
   - `compilacion-e-instalacion.md`: del push al iPhone.
   - `conceptos-ios.md`: glosario.
   - `flujo-de-trabajo.md`: Git Flow.
   - `adr/`: decisiones.

Idioma: documentación, comentarios e interfaz en **español**; identificadores
en **inglés**.

## Alternativas consideradas

- **Solo un catálogo DocC:** no se lee sin compilar y pierde los diagramas.
- **Diagramas como imágenes:** no se revisan en un diff y se desactualizan.

## Consecuencias

- Todo se lee en GitHub y los diagramas se editan en el mismo pull request
  que el código.
- Los diagramas se actualizan a mano cuando cambia el diseño.
