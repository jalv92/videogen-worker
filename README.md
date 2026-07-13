# videogen-worker

Worker serverless de ComfyUI para RunPod. Genera **video** (LTX-2.3, con audio) e **imagen** (Krea 2 turbo) con los modelos horneados dentro de la imagen Docker, de modo que funciona con GPUs de cualquier datacenter del mundo sin descargar nada en cada arranque.

Basado en [`runpod/worker-comfyui`](https://github.com/runpod-workers/worker-comfyui): se le envía un workflow en formato API por `/run` o `/runsync` y devuelve el resultado (imagen/video) en base64.

Ver `DEPLOY.md` para desplegarlo en RunPod (Serverless → Import Git Repository).
