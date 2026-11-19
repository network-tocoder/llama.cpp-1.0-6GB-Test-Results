#!/bin/bash
# Quick writing-speed check against the running server (port 8081)
for topic in "how a CPU cache works" "how a GPU renders a frame" "how TCP handles packet loss"; do
  curl -s localhost:8081/completion -d "{\"prompt\":\"Explain in detail $topic, with examples.\",\"n_predict\":800,\"cache_prompt\":false}" \
  | python3 -c "import sys,json;t=json.load(sys.stdin)['timings'];print('write %.1f tok/s  (%d tokens)'%(t['predicted_per_second'],t['predicted_n']))"
done
