# Worker serverless de ComfyUI para RunPod: video (LTX-2.3) e imagen (Krea 2).
# Modelos horneados dentro de la imagen -> funciona con GPUs de todo el mundo,
# sin disco de red y sin descargar nada en cada arranque.
#
# Base = worker-comfyui (trae el handler serverless, comfy-cli y las herramientas).
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# ---------------------------------------------------------------------------
# 1) Actualizar ComfyUI al ultimo master (necesario para el tipo CLIP 'krea2',
#    que la version 5.8.6 aun no incluye).
# ---------------------------------------------------------------------------
RUN cd /comfyui \
 && git fetch --depth 1 origin master \
 && git checkout -f master \
 && git reset --hard origin/master \
 && pip install --no-cache-dir -r requirements.txt

# ---------------------------------------------------------------------------
# 2) Custom nodes (GGUF para el video LTX, KJNodes para VAELoaderKJ, etc.)
# ---------------------------------------------------------------------------
RUN comfy-node-install comfyui-gguf comfyui-kjnodes

# ---------------------------------------------------------------------------
# 3) Modelos (~50 GB) con el cliente oficial de HuggingFace (soporta Xet).
#    aria2c/comfy fallaban contra la CDN Xet de HF; 'hf download' lo maneja bien.
# ---------------------------------------------------------------------------
RUN pip install --no-cache-dir -U "huggingface_hub[hf_transfer,cli]" hf_xet
COPY download_models.sh /tmp/download_models.sh
RUN bash /tmp/download_models.sh
