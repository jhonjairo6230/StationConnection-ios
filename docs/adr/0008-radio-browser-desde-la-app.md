# 0008. Llamar a Radio Browser desde la app y permitir audio por http

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** nueva.

## Contexto

En la web, el navegador no llama a Radio Browser: pasa por `/api/*` del
servidor (Next.js), y solo se aceptan streams **https** porque el navegador
bloquea el contenido mixto. Una app nativa no tiene CORS ni contenido mixto,
y muchas emisoras (por ejemplo, regionales de Colombia) solo transmiten por
**http**.

## Decisión

1. La app llama **directamente** a la API pública de Radio Browser con
   `URLSession` (`RadioBrowserDirectory`): prueba como mucho dos espejos con
   timeout corto, cachea géneros y países una hora y envía un `User-Agent`
   propio, como pide su guía de uso.
2. **Audio por http permitido solo para medios**:
   `NSAppTransportSecurity → NSAllowsArbitraryLoadsForMedia` en
   `project.yml`. Las demás conexiones (API, logos) siguen exigiendo https;
   los logos http se descartan.
3. Los enlaces externos (sitio web) se validan: solo `http`/`https`.

## Alternativas consideradas

- **Usar el backend de la web (`/api/*` en Vercel):** reutiliza la caché del
  servidor, pero la app dependería de que la web esté desplegada y del plan
  gratuito de Vercel.
- **Solo https (como en la web):** más simple, pero se pierden muchas
  emisoras.
- **`NSAllowsArbitraryLoads` global:** abriría también las peticiones de
  datos; innecesario.

## Consecuencias

- La app funciona sin servidor propio y con más emisoras que la web.
- El audio por http no va cifrado (es radio pública; no hay datos del
  usuario).
- Si Radio Browser cambia su API, solo cambia la capa Data.
