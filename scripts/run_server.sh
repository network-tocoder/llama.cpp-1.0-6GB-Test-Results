#!/bin/bash
# The exact server settings from the video (6 GB GPU, 32 GB RAM)
M=$(find ~/models -name "*UD-Q4_K_M*.gguf" | head -1)
cd ~/llama.cpp
./build/bin/llama-server -m "$M" \
  -c 65536 -ctk q8_0 -ctv q8_0 -fa on -t 8 \
  -cmoe --moe-cache-mib 2000 --moe-cache-cpu-share 0 \
  -lm none --jinja -a qwen36-35b --port 8081
# More V ram?  raise --moe-cache-mib (keep ~0.5 GB free).
# Less RAM?    remove "-lm none" (the model is then read from the drive: works, but slower).
# Set -t to your number of physical CPU cores.
