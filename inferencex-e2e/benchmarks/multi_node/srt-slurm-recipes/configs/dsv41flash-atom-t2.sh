#!/usr/bin/env bash
set -eo pipefail

# Applies ROCm/ATOM#3773 (commit ea0732558, P/D early handoff, open) to the image's editable /app/ATOM checkout.
# The code is inert unless ATOM_PD_EARLY_HANDOFF=1, which the recipe sets on prefill only.
patch=/configs/patches/dsv41flash-atom-t2-early-handoff.patch
echo "6cafff05d3f0f3bb901da60b0b89ce77fba7028c09b14559301082b6b608eb2e  ${patch}" | sha256sum --check --strict -

cd /app/ATOM
# Colocated workers may share one writable container root.
exec 9>/tmp/dsv41flash-atom-t2.lock
flock 9
if git apply --reverse --check "${patch}" 2>/dev/null; then
    echo "ROCm/ATOM#3773 is already applied to /app/ATOM"
else
    git apply --check "${patch}"
    git apply "${patch}"
    echo "Applied ROCm/ATOM#3773 to /app/ATOM"
fi
git apply --reverse --check "${patch}"
python3 -m py_compile atom/entrypoints/openai/api_server.py \
    atom/kv_transfer/disaggregation/mooncake/mooncake_connector.py \
    atom/model_engine/engine_core_mgr.py atom/utils/envs.py
