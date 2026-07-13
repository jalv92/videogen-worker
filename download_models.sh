#!/usr/bin/env bash
# Descarga los modelos desde HuggingFace con el cliente oficial (soporta Xet).
set -euo pipefail
export HF_HUB_ENABLE_HF_TRANSFER=1

# dl <repo> <ruta_en_repo> <dir_destino> <nombre_destino>
dl() {
  echo ">>> $1 :: $2"
  hf download "$1" "$2" --local-dir /tmp/hf \
    || huggingface-cli download "$1" "$2" --local-dir /tmp/hf --local-dir-use-symlinks False
  mkdir -p "$3"
  mv "/tmp/hf/$2" "$3/$4"
}

# --- VIDEO (LTX-2.3) ---
dl unsloth/LTX-2.3-GGUF  ltx-2.3-22b-dev-Q4_K_M.gguf                                                   /comfyui/models/unet                   ltx-2.3-22b-dev-Q4_K_M.gguf
dl Comfy-Org/ltx-2       split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors                /comfyui/models/text_encoders          gemma_3_12B_it_fp4_mixed.safetensors
dl unsloth/LTX-2.3-GGUF  text_encoders/ltx-2.3-22b-dev_embeddings_connectors.safetensors              /comfyui/models/text_encoders          ltx-2.3-22b-dev_embeddings_connectors.safetensors
dl unsloth/LTX-2.3-GGUF  vae/ltx-2.3-22b-dev_video_vae.safetensors                                    /comfyui/models/vae                    ltx-2.3-22b-dev_video_vae.safetensors
dl unsloth/LTX-2.3-GGUF  vae/ltx-2.3-22b-dev_audio_vae.safetensors                                    /comfyui/models/vae                    ltx-2.3-22b-dev_audio_vae.safetensors
dl Comfy-Org/ltx-2.3     split_files/loras/ltx_2.3_22b_distilled_1.1_lora_dynamic_fro09_avg_rank_111_bf16.safetensors /comfyui/models/loras     ltx_2.3_22b_distilled_1.1_lora_dynamic_fro09_avg_rank_111_bf16.safetensors
dl Lightricks/LTX-2.3    ltx-2.3-spatial-upscaler-x2-1.1.safetensors                                  /comfyui/models/latent_upscale_models  ltx-2.3-spatial-upscaler-x2-1.1.safetensors

# El text encoder LTX-AV tambien busca los connectors en checkpoints/.
mkdir -p /comfyui/models/checkpoints
cp /comfyui/models/text_encoders/ltx-2.3-22b-dev_embeddings_connectors.safetensors /comfyui/models/checkpoints/

# --- IMAGEN (Krea 2 turbo). El repo trae *_fp8_scaled; lo renombramos a *_fp8. ---
dl Comfy-Org/Krea-2      diffusion_models/krea2_turbo_fp8_scaled.safetensors                          /comfyui/models/unet                   krea2_turbo_fp8.safetensors
dl Comfy-Org/Krea-2      loras/krea2_turbo_lora_rank_64_bf16.safetensors                              /comfyui/models/loras                  krea2_turbo_lora_rank_64_bf16.safetensors
dl Comfy-Org/Krea-2      text_encoders/qwen3vl_4b_fp8_scaled.safetensors                              /comfyui/models/text_encoders          qwen3vl_4b_fp8_scaled.safetensors
dl Comfy-Org/Krea-2      vae/qwen_image_vae.safetensors                                               /comfyui/models/vae                    qwen_image_vae.safetensors

rm -rf /tmp/hf
echo ">>> Todos los modelos descargados."
