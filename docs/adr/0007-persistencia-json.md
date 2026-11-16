# 0007. Guardar la biblioteca en archivos JSON

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** nueva. DrawPad eligió SwiftData para su galería (su ADR 0007);
  aquí se evaluó lo mismo y se eligió otra cosa.

## Contexto

La app guarda tres listas pequeñas en el dispositivo: favoritas (en el orden
del usuario, que es el de ⏮/⏭), recientes (máx. 12) e historial de
canciones (máx. 50). Además, las favoritas se **exportan e importan** en un
archivo compatible con la app web.

## Decisión

Guardar cada lista en un archivo JSON en `Application Support/StationConnection/`
con `JSONFileRepository<Item>`, un único tipo genérico que cumple los tres
puertos del dominio (`FavoritesRepository`, `RecentsRepository`,
`SongHistoryRepository`). Escritura atómica (`.atomic`). `Station` usa los
**mismos nombres de campo que la web** (`streamUrl`, `hls`…).

## Alternativas consideradas

- **SwiftData (como DrawPad):** útil para consultas, orden y muchos
  registros; aquí son listas de decenas de elementos donde el **orden manual**
  es lo importante, y habría que mapear `@Model` ↔ `Station` y además
  serializar a JSON para el respaldo.
- **`UserDefaults`:** pensado para ajustes pequeños, no para listas de
  objetos.
- **Core Data:** el esquema se edita con Xcode; inviable sin Mac.
- **iCloud / CloudKit:** sincronizaría entre dispositivos, pero requiere
  cuenta de pago.

## Consecuencias

- Muy poco código, fácil de probar con una carpeta temporal.
- El archivo de favoritas es casi el mismo formato que el respaldo.
- Se reescribe la lista entera en cada cambio (despreciable con este tamaño).
- Si algún día hay muchas más cosas que guardar, un ADR nuevo puede pasar a
  SwiftData sin tocar el dominio.
