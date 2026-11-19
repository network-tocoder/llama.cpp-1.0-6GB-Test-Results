#!/bin/bash
# Build llama.cpp v1.0.0 with CUDA and download the model (about 22 GB)
apt update && apt install -y git cmake build-essential libcurl4-openssl-dev python3-pip tmux
git clone --depth 1 --branch v1.0.0 https://github.com/ggml-org/llama.cpp ~/llama.cpp
cd ~/llama.cpp
# CUDA arch: 86 = RTX 30xx / RTX A2000, 89 = RTX 40xx, 120 = RTX 50xx
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=86 -DLLAMA_USE_PREBUILT_UI=OFF
cmake --build build -j $(nproc) --target llama-server
pip install -U "huggingface_hub[cli]"
hf download unsloth/Qwen3.6-35B-A3B-GGUF --include "*UD-Q4_K_M*" --local-dir ~/models
