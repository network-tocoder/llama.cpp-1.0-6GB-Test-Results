# llama.cpp 1.0 + Qwen 35B on a 6GB GPU

![llama.cpp](https://img.shields.io/badge/llama.cpp-v1.0.0-orange) ![GPU](https://img.shields.io/badge/GPU-6GB%20V%20ram-76b900) ![RAM](https://img.shields.io/badge/RAM-32GB-0ea5e9) ![Model](https://img.shields.io/badge/Model-Qwen3.6%2035B--A3B-blue) ![Agent](https://img.shields.io/badge/Agent-Pi-black) ![Cost](https://img.shields.io/badge/Cloud%20API-%240-brightgreen)

📺 **Video:** [Qwen 35B Is Now Insanely Fast on a 6GB GPU! (New llama.cpp)](https://www.youtube.com/watch?v=p3PFSpXtJnw&t=5s) *(add the video link)*

A 35B model is 22 GB on disk, almost **4× bigger than a 6 GB graphics card**. With llama.cpp 1.0 it runs at about **40 tok/s** and builds full apps through a coding agent, fully offline.

| | First run (no cache) | Expert cache on (2 GB) |
|---|---|---|
| **Writing** | 30.2 tok/s | **40.0 tok/s** |
| **V ram used** | 3.5 of 6 GB | **5.5 of 6 GB** |
| **During the 4 builds** | | ~37–38 tok/s writing · ~500–600 tok/s reading |

---

## The recipe

```bash
llama-server -m Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
  -c 65536 -ctk q8_0 -ctv q8_0 -fa on -t 8 \
  -cmoe --moe-cache-mib 2000 --moe-cache-cpu-share 0 \
  -lm none --jinja -a qwen36-35b --port 8081
```

| Flag | What it does |
|---|---|
| `-cmoe` | keep the MoE experts in system RAM, not on the GPU |
| `--moe-cache-mib 2000` | keep the most-used experts in 2 GB of V ram (off by default) |
| `-lm none` | load the whole model into RAM at start, instead of reading it from the drive as it goes |
| `-c 65536 -ctk q8_0 -ctv q8_0` | 64K context with an 8-bit KV cache |
| `-fa on` | flash attention |

**More V ram?** Raise `--moe-cache-mib` and keep about 0.5 GB free.
**Less RAM?** Remove `-lm none`. The model is then read from the drive: it still works, just slower.

---

## Why it works

Qwen 3.6 35B is a **mixture of experts** model: 35B parameters in total, but only about **3B are used for each word**. So the parts that aren't active don't need to be on the GPU:

| Level | Speed | Size here | What lives there |
|---|---|---|---|
| GPU | fastest, smallest | 6 GB | attention, KV cache, and (with the cache on) the busiest experts |
| System RAM | slower, bigger, cheaper | 32 GB | all the other experts |
| NVMe SSD | slowest, largest | 22 GB file | only the model file (with `-lm none`) |

---

## The stack

| Part | Spec |
|---|---|
| Engine | llama.cpp **v1.0.0**, built from source with CUDA (`-DCMAKE_CUDA_ARCHITECTURES=86 -DLLAMA_USE_PREBUILT_UI=OFF`) |
| Model | **Qwen3.6-35B-A3B**, Unsloth **UD-Q4_K_M**, 22.1 GB, [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) |
| GPU | **6 GB** V ram (6,138 MiB) |
| RAM | **32 GB** |
| CPU threads | 8 |
| Context / KV | 64K, `q8_0` KV cache, flash attention on |
| Agent | [Pi](https://pi.dev) coding agent, config in [`config/models.json`](config/models.json) |

---

## The builds

Each build was a **single prompt** in a fresh Pi session and its own folder. Simple first, then harder.

| Build | Lines | Time | Context used (of 64K) | Fixes | Files |
|---|---|---|---|---|---|
| ☕ Coffee shop landing page | 618 | ~3.5 min | ~14% | 0 | [[prompt](projects/coffee/PROMPT.md) |
| 🎵 Music player app | 450 | ~2 min | ~12% | 0 | [prompt](projects/player/PROMPT.md) |
| 🏝️ 3D lighthouse island | 749 | | 18.6% | 0 | [prompt](projects/lighthouse/PROMPT.md) |
| 📷 3D vintage film camera | 965 | | 51% | 1 | [prompt](projects/camera/PROMPT.md) |

- **Camera:** the first version (955 lines) had one error that stopped the scene loading. The console error was pasted back into Pi, and it fixed it. The file here is the fixed version.
- **3D builds** load Three.js from a CDN, so they need internet the first time you open them.
- **Prompts** were reconstructed from the finished builds and the video; the original wording may differ slightly.

Full data: [`results.csv`](results.csv) · [`results/builds.csv`](results/builds.csv)

---

## Try it yourself

You'll need a GPU with **6 GB+ V ram**, **32 GB RAM**, and about **25 GB** of free disk space.

```bash
bash scripts/setup.sh        # build llama.cpp v1.0.0 + download the model
bash scripts/run_server.sh   # start the server with the settings above
bash scripts/speed_test.sh   # quick writing-speed check (in a second terminal)
```

Then point Pi at it:

```bash
mkdir -p ~/.pi/agent && cp config/models.json ~/.pi/agent/models.json
mkdir -p ~/work/coffee && cd ~/work/coffee && pi
```

Change `-DCMAKE_CUDA_ARCHITECTURES` in `setup.sh` for your card: **86** = RTX 30 / A2000, **89** = RTX 40, **120** = RTX 50.

---

## Read these numbers carefully

Every number here comes from **one machine**: this GPU, this RAM, this model file, this llama.cpp version. Your speed will depend on your GPU, your RAM speed and your PCIe link. Please share yours.

---

## 📺 The series

| Part | Video | GPU | Repo |
|---|---|---|---|
| 1 | Run a 125B model on one GPU (Strata) | RTX 3090 24 GB | |
| 2 | Free local AI coding agent (Strata + opencode) | RTX 4060 Ti 16 GB | |
| 3 | 125B on 12 GB V ram (Strata + Pi 1.0) | RTX 3080 Ti 12 GB | [repo](https://github.com/network-tocoder/125B-Local-AI-on-a-12GB-GPU-Strata-Pi-1.0-Coding-Agent) |
| 4 | llama.cpp 1.0: two flags, 12 GB GPU | RTX 4070 Super 12 GB | |
| 5 | Can llama.cpp 1.0 beat Strata at coding? | RTX 3080 Ti 12 GB | |
| **6** | **llama.cpp 1.0 + Qwen 35B on 6 GB** | **6 GB** | this repo |

⭐ If this helped, star the repo so more people find it. **Share your GPU, RAM and tok/s** in an issue or in the video comments.

**Sources:** [llama.cpp v1.0.0 release](https://github.com/ggml-org/llama.cpp/releases/tag/v1.0.0) · [MoE cache docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/moe-cache.md) · [Unsloth Qwen3.6-35B-A3B GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) · [Pi coding agent](https://pi.dev)
