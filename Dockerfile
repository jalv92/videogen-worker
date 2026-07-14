# Worker serverless de ComfyUI para RunPod: video (LTX-2.3) e imagen (Krea 2).
# Modelos horneados -> funciona con GPUs de todo el mundo, sin descargar en cada arranque.
#
# La imagen base tiene DOS entornos python; ComfyUI corre en /opt/venv (PATH lo
# prioriza) con torch 2.11+cu128 (sm_120 para RTX 5090), transformers 4.57.6 y
# huggingface_hub 0.36.2 -> ya sano. Solo actualizamos el CODIGO de ComfyUI a
# master (para el tipo CLIP 'krea2') y horneamos nodos+modelos, SIN romper /opt/venv.
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# Libs de sistema para KJNodes (opencv) + git.
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 git \
 && rm -rf /var/lib/apt/lists/*

# transformers 4.57.6 EXIGE huggingface_hub<1.0 (con >=1.0 'import transformers' aborta).
RUN printf 'transformers==4.57.6\nhuggingface_hub>=0.34,<1.0\nnumpy<2\n' > /tmp/constraints.txt

# 1) ComfyUI -> master (para 'krea2'). torch se FILTRA de requirements para
#    conservar el 2.11+cu128 (sm_120) de /opt/venv. Constraints evitan que
#    transformers/hub se muevan a versiones que rompen el import.
RUN cd /comfyui \
 && git fetch --depth 1 origin master \
 && git checkout -f master \
 && git reset --hard origin/master \
 && grep -viE '^(torch|torchvision|torchaudio)([=<>~!; ]|$)' requirements.txt > /tmp/reqs.txt \
 && pip install --no-cache-dir -r /tmp/reqs.txt -c /tmp/constraints.txt

# 2) Custom nodes clonados en custom_nodes y sus deps instaladas en /opt/venv
#    (el mismo montaje que ya genero video en nuestras pruebas de pod).
RUN cd /comfyui/custom_nodes \
 && git clone --depth 1 https://github.com/city96/ComfyUI-GGUF \
 && git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes \
 && pip install --no-cache-dir -r ComfyUI-GGUF/requirements.txt -r ComfyUI-KJNodes/requirements.txt -c /tmp/constraints.txt

# 3) hf_xet (para descargas Xet) + re-fijar el conjunto critico en /opt/venv.
RUN pip install --no-cache-dir "huggingface_hub[hf_xet]>=0.34,<1.0" "transformers==4.57.6" "numpy<2"

# 4) TEST DE HUMO build-safe (sin GPU): NO usa get_arch_list (que da [] sin GPU).
#    Verifica que torch sigue en cu128>=2.7 (=> tiene kernels sm_120), que hub
#    sigue en 0.x y transformers importa, y que el core trae soporte krea2.
RUN python -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda); assert torch.version.cuda=='12.8', 'torch no cu128: '+str(torch.version.cuda); v=tuple(int(x) for x in torch.__version__.split('+')[0].split('.')[:2]); assert v>=(2,7), 'torch<2.7: '+torch.__version__"
RUN python -c "import huggingface_hub as h; assert int(h.__version__.split('.')[0])==0, 'hub 1.x: '+h.__version__; import transformers as t; print('OK transformers', t.__version__, 'hub', h.__version__)"
RUN grep -q 'KREA2' /comfyui/comfy/sd.py && echo "OK krea2 en el core"
# Carga TODOS los nodos (core + GGUF + KJNodes) en CPU y sale: si algun nodo o
# dependencia no importa, el build falla aqui (barato) en vez del worker (caro).
RUN cd /comfyui && python main.py --cpu --quick-test-for-ci

# 5) Modelos (~50 GB) via Xet.
ENV HF_XET_HIGH_PERFORMANCE=1
COPY download_models.sh /tmp/download_models.sh
RUN bash /tmp/download_models.sh
