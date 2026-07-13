# Como desplegar el worker serverless en RunPod

## Paso 1 - Conectar RunPod a GitHub
En https://console.runpod.io -> **Settings -> Connections -> GitHub -> Connect**, y autoriza el acceso al repo `videogen-worker`.

## Paso 2 - Crear el endpoint serverless
Console -> **Serverless -> New Endpoint -> Import Git Repository**:
- Repo: `jalv92/videogen-worker`, rama `main`, Dockerfile: `Dockerfile`
- **GPU**: marca RTX 5090 y anade RTX 4090 y RTX 6000 Ada como respaldo (prioridad por disponibilidad)
- **Regiones/Data centers**: dejalo en TODOS (mundial) para maxima disponibilidad
- Workers: Min 0 (escala a cero, no cobra en reposo), Max 1-2
- FlashBoot: activado
- Deja que construya (build ~15-30 min la primera vez). Progreso en la pestana "Builds".

## Paso 3 - Pasame el Endpoint ID
Cuando el endpoint este "Ready", dime su **Endpoint ID**. Con eso adapto el orquestador para llamarlo por `/run` y recibir el video/imagen, y hacemos la prueba final.

## Notas
- La misma API key de RunPod sirve para llamar al endpoint.
- Coste: solo pagas los segundos de generacion (~$0.002-0.005/imagen, ~$0.04-0.07/video en 5090).
- Para actualizar modelos/nodos: editas el Dockerfile, haces push, y RunPod reconstruye.
