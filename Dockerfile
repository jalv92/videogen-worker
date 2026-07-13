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
# 3) Modelos de VIDEO (LTX-2.3, ~31 GB)
# ---------------------------------------------------------------------------
RUN comfy model download --url https://huggingface.co/unsloth/LTX-2.3-GGUF/resolve/main/ltx-2.3-22b-dev-Q4_K_M.gguf                                                --relative-path models/unet                  --filename ltx-2.3-22b-dev-Q4_K_M.gguf
RUN comfy model download --url https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors                --relative-path models/text_encoders         --filename gemma_3_12B_it_fp4_mixed.safetensors
RUN comfy model download --url https://huggingface.co/unsloth/LTX-2.3-GGUF/resolve/main/text_encoders/ltx-2.3-22b-dev_embeddings_connectors.safetensors           --relative-path models/text_encoders         --filename ltx-2.3-22b-dev_embeddings_connectors.safetensors
RUN comfy model download --url https://huggingface.co/unsloth/LTX-2.3-GGUF/resolve/main/vae/ltx-2.3-22b-dev_video_vae.safetensors                                 --relative-path models/vae                   --filename ltx-2.3-22b-dev_video_vae.safetensors
RUN comfy model download --url https://huggingface.co/unsloth/LTX-2.3-GGUF/resolve/main/vae/ltx-2.3-22b-dev_audio_vae.safetensors                                 --relative-path models/vae                   --filename ltx-2.3-22b-dev_audio_vae.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/ltx-2.3/resolve/main/split_files/loras/ltx_2.3_22b_distilled_1.1_lora_dynamic_fro09_avg_rank_111_bf16.safetensors --relative-path models/loras --filename ltx_2.3_22b_distilled_1.1_lora_dynamic_fro09_avg_rank_111_bf16.safetensors
RUN comfy model download --url https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.1.safetensors                                 --relative-path models/latent_upscale_models --filename ltx-2.3-spatial-upscaler-x2-1.1.safetensors

# El text encoder LTX-AV tambien busca los connectors en checkpoints/.
RUN cp /comfyui/models/text_encoders/ltx-2.3-22b-dev_embeddings_connectors.safetensors /comfyui/models/checkpoints/

# ---------------------------------------------------------------------------
# 4) Modelos de IMAGEN (Krea 2 turbo, ~19 GB)
#    Nota: el fichero del repo es *_fp8_scaled; lo guardamos como *_fp8 para
#    que coincida con el nombre que usa tu workflow.
# ---------------------------------------------------------------------------
RUN comfy model download --url https://huggingface.co/Comfy-Org/Krea-2/resolve/main/diffusion_models/krea2_turbo_fp8_scaled.safetensors --relative-path models/unet          --filename krea2_turbo_fp8.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/Krea-2/resolve/main/loras/krea2_turbo_lora_rank_64_bf16.safetensors      --relative-path models/loras         --filename krea2_turbo_lora_rank_64_bf16.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/Krea-2/resolve/main/text_encoders/qwen3vl_4b_fp8_scaled.safetensors      --relative-path models/text_encoders --filename qwen3vl_4b_fp8_scaled.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/Krea-2/resolve/main/vae/qwen_image_vae.safetensors                       --relative-path models/vae           --filename qwen_image_vae.safetensors
