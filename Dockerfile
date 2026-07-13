# Worker serverless de ComfyUI para RunPod: video (LTX-2.3) e imagen (Krea 2).
# Modelos horneados dentro de la imagen -> funciona con GPUs de todo el mundo,
# sin disco de red y sin descargar nada en cada arranque.
#
# Base = worker-comfyui (trae el handler serverless, comfy-cli, torch cu128 con
# soporte sm_120 para la RTX 5090, y las herramientas). La 5.8.6 ya corrio video
# LTX-2.3 en nuestras pruebas; solo actualizamos el core para soportar Krea 2.
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# Libs de sistema que KJNodes (opencv) necesita en runtime.
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 \
 && rm -rf /var/lib/apt/lists/*

# Constraints: impiden que la actualizacion del core o los custom nodes muevan
# versiones criticas. transformers 4.57.6 EXIGE huggingface_hub <1.0 (con >=1.0
# 'import transformers' aborta). numpy<2 por compatibilidad con gguf/numba.
RUN printf 'transformers==4.57.6\nhuggingface_hub>=0.34,<1.0\nnumpy<2\n' > /tmp/constraints.txt

# ---------------------------------------------------------------------------
# 1) Actualizar ComfyUI al ultimo master (necesario para el tipo CLIP 'krea2').
#    NO se toca torch (se filtra de requirements para conservar el cu128/sm_120
#    del base) y se aplican los constraints para no romper transformers/hub.
# ---------------------------------------------------------------------------
RUN cd /comfyui \
 && git fetch --depth 1 origin master \
 && git checkout -f master \
 && git reset --hard origin/master \
 && grep -viE '^(torch|torchvision|torchaudio)([=<>~!; ]|$)' requirements.txt > /tmp/reqs.txt \
 && pip install --no-cache-dir -r /tmp/reqs.txt -c /tmp/constraints.txt

# ---------------------------------------------------------------------------
# 2) Cliente HF con Xet (compatible con hub <1.0) + custom nodes.
# ---------------------------------------------------------------------------
RUN pip install --no-cache-dir "huggingface_hub[hf_xet]>=0.34,<1.0" -c /tmp/constraints.txt
RUN comfy-node-install comfyui-gguf comfyui-kjnodes

# 3) Re-fijar el conjunto critico por si un custom node lo movio.
RUN pip install --no-cache-dir "huggingface_hub[hf_xet]>=0.34,<1.0" "transformers==4.57.6" "numpy<2"

# ---------------------------------------------------------------------------
# 4) TEST DE HUMO (falla el build barato si algo esta roto, no el worker caro):
#    - torch conserva kernels sm_120 (RTX 5090 Blackwell)
#    - huggingface_hub sigue en 0.x y transformers importa sin ImportError
#    - el core tiene soporte krea2
# ---------------------------------------------------------------------------
RUN python -c "import torch; al=torch.cuda.get_arch_list(); print('ARCH', al); assert any('120' in a for a in al), 'FALTA sm_120: '+str(al)"
RUN python -c "import huggingface_hub as h; assert int(h.__version__.split('.')[0])==0, 'hub 1.x: '+h.__version__; import transformers as t; print('OK transformers', t.__version__, 'hub', h.__version__)"
RUN grep -q 'KREA2' /comfyui/comfy/sd.py && echo "OK krea2 en el core"

# ---------------------------------------------------------------------------
# 5) Modelos (~50 GB) via Xet.
# ---------------------------------------------------------------------------
ENV HF_XET_HIGH_PERFORMANCE=1
COPY download_models.sh /tmp/download_models.sh
RUN bash /tmp/download_models.sh
