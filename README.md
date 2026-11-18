# llama.cpp 1.0: Two Flags, One 12GB GPU, a 125B Model

![llama.cpp](https://img.shields.io/badge/llama.cpp-v1.0.0-orange) ![GPU](https://img.shields.io/badge/GPU-RTX%204070%20Super%2012GB-76b900) ![Model](https://img.shields.io/badge/Model-Swift%201.5%20125B-blue) ![Cost](https://img.shields.io/badge/Cloud%20API-%240-brightgreen)

📺 **Video:** [Two Flags Made llama.cpp 1.0 Way Faster (12GB GPU)](https://www.youtube.com/watch?v=p3PFSpXtJnw) *(add the video link)*

I updated to llama.cpp 1.0 and got **exactly the same speed** as before. Then I changed two flags.

| | Default (just upgraded) | Two flags | Gain |
|---|---|---|---|
| **Writing** | 16.3 tok/s | **26.5 tok/s** | **+63%** |
| **Reading a 16K-token prompt** | 107 tok/s (150 s) | **201 tok/s (80 s)** | **+88%** |

Both features ship with 1.0. **Both are off by default.**

---

## The recipe

```bash
llama-server -m Swift-Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-00001-of-00002.gguf \
  -cmoe -lm none \
  --moe-cache-mib 4864 --moe-cache-cpu-share 0 \
  -ctk q8_0 -ctv q8_0 -fa on -c 65536 -t 20
```

| Flag | What it does | Default |
|---|---|---|
| `-cmoe` | keep MoE experts in system RAM | off |
| `--moe-cache-mib N` | keep the most-used experts in V ram | **0 (disabled)** |
| `--moe-cache-cpu-share F` | share of cache misses the CPU computes instead of uploading | **0** |
| `-lm none` | load the model pinned in RAM instead of memory-mapped | **mmap** |

**Have the RAM?** Use `-lm none`, give the cache every MB you can, and let the tuning script pick the share (it chose **0** here).
**Don't have the RAM?** Stay memory-mapped, turn the cache on, and push `--moe-cache-cpu-share` to **0.8–0.95** (that alone gave **+52%**).

---

## The stack

| Part | Spec |
|---|---|
| Engine | llama.cpp **v1.0.0** (build 1, commit `b1b770d`), built from source with CUDA |
| Model | **Swift 1.5** (125B MoE, based on Qwen 3.8 Flash Next), GSQ-RCO **IQ3_XXS**, 76 GB, [ukisai/Swift-1.5-Qwen3.8-Flash-Next-GSQ-RCO-GGUF](https://huggingface.co/ukisai/Swift-1.5-Qwen3.8-Flash-Next-GSQ-RCO-GGUF) |
| Experts | 40,925 MiB of experts (reported by the tuning script) |
| GPU | RTX 4070 Super **12 GB**, PCIe **Gen 3** x16 |
| CPU | 2× Xeon E5-2673 v4 (80 threads) |
| RAM | 125 GB |
| Driver / CUDA | 580.82.09 / CUDA 13.0 driver, built with CUDA 12.8 (`-DCMAKE_CUDA_ARCHITECTURES=89`) |
| Context / KV | 64K, `q8_0` KV cache, flash attention on |

---

## All results

Method: 3 × 800-token answers on **different topics** (CPU cache, GPU frame, TCP loss) so the cache can't memorize one answer, then one **16,086-token prompt** for reading speed. One test at a time.

| Test | Load | Cache | Share | Writing (3 runs) | Reading |
|---|---|---|---|---|---|
| Default | mmap | 0 | 0 | 16.6 / 16.3 / 16.3 | 107 |
| Cache on | mmap | 5000 | 0 | 19.4 / 18.9 / 16.8 | 119 |
| CPU share 0.5 | mmap | 5000 | 0.5 | 19.1 / 17.6 / 17.2 | 116 |
| **CPU share 0.95** | mmap | 5000 | 0.95 | 20.7 / **24.9 / 24.7** | 118 |
| Pinned + 0.95 | none | 5000 | 0.95 | 23.9 / 23.8 / 22.1 | 199 |
| Pinned (mlock) + 0.95 | mlock | 5000 | 0.95 | 20.1 / 21.3 / 20.1 | 199 |
| **Pinned + share 0** | none | 5000 | 0 | **26.7 / 27.1 / 25.8** | **201** |
| + draft mode (`--spec-default`) | none | 5000 | 0 | 25.1 / 27.2 / 26.1 | 202 |
| + 40 threads | none | 5000 | 0 | 27.8 / 27.3 / 26.3 | 202 |
| Bigger batch (`-ub 2048`) | mmap | 5000 | 0.95 | out of GPU memory | — |

Full data: [`results.csv`](results.csv) · raw output: [`results/raw_results.txt`](results/raw_results.txt)

### What the tuning script measured

| | Memory-mapped (default) | Pinned (`-lm none`) |
|---|---|---|
| GPU upload speed | **4.4 GiB/s** | **10.5 GiB/s** (2.4× faster, same PCIe slot) |
| CPU read speed | 8.5 GiB/s | 15.1 GiB/s |
| Recommended share | **0.8** | **0** |
| Predicted (warm cache) | 26.7 tok/s | 29.6 tok/s |
| My 3-topic test | 20.8 tok/s | 26.4 tok/s |

Memory-mapped: uploads are slow, so let the CPU handle misses. Pinned: uploads are fast, so let the GPU do it.
Tables: [`results/tune_mmap.md`](results/tune_mmap.md) · [`results/tune_pinned.md`](results/tune_pinned.md)

### Also tested

| | Result |
|---|---|
| KV cache f16 vs q8_0 (64K ctx) | 7,514 MiB vs **6,626 MiB** of V ram (−888 MiB) |
| FP8 KV cache (`-ctk f8_e4m3`) | ❌ `FP8 cache is not supported for architecture 'qwen4exp'` |

---

## How much RAM do you need?

| GPU | Model file | RAM | Notes |
|---|---|---|---|
| 12 GB | 3-bit IQ3_XXS (76 GB) | **~85 GB+** (96 GB machine) | everything in this repo |
| 12 GB | 4-bit IQ4_XS (94 GB) | ~128 GB | |
| 24 GB | 4-bit IQ4_XS (94 GB) | ~96 GB | more experts fit on the GPU |
| any | any | 64 GB | runs memory-mapped (NVMe reads), cache + CPU share + tuner work, **no pinned loading** |

Only **mixture-of-experts** models benefit from the expert cache; dense models (e.g. 27B) don't.

---

## Reproduce it

```bash
bash scripts/setup.sh                    # build llama.cpp v1.0.0 + download the model
cp scripts/run.sh ~/run.sh
bash scripts/tests.sh                    # every test from the video, one at a time
```

⚠️ Run tests **from one terminal only**. Two servers on the same port and GPU will invalidate each other's numbers.

---

## Read these numbers carefully

Every number here is a photo of **one machine**: this GPU, this PCIe 3 slot, these CPUs, this file, this version. On a faster link the CPU share may matter less; with a smaller cache it may matter more. Run the tuning script on your own machine.

My Strata result from the previous video (~75 tok/s) was a **different card and machine**, so it's a reference, not a head-to-head.

---

## 📺 The series

| Part | Video | GPU | Repo |
|---|---|---|---|
| 1 | Run a 125B model on one GPU (Strata) | RTX 3090 24 GB | |
| 2 | Free local AI coding agent (Strata + opencode) | RTX 4060 Ti 16 GB | |
| 3 | 125B on 12 GB V ram (Strata + Pi 1.0) | RTX 3080 Ti 12 GB | [repo](https://github.com/network-tocoder/125B-Local-AI-on-a-12GB-GPU-Strata-Pi-1.0-Coding-Agent) |
| **4** | **llama.cpp 1.0: two flags, 12 GB GPU** | RTX 4070 Super 12 GB | this repo |

⭐ If this helped, star the repo so more people find it. **Tell me what the tuning script recommends on your machine** in an issue or in the video comments.

**Sources:** [llama.cpp v1.0.0 release](https://github.com/ggml-org/llama.cpp/releases/tag/v1.0.0) · [Hugging Face blog: llama.cpp v1.0.0](https://huggingface.co/blog/ggml-org/llama-cpp-v1) · [MoE cache docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/moe-cache.md)
