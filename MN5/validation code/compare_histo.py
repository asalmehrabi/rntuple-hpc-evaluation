import json
import numpy as np

# Load JSON files
with open("inference_output.json") as f1:
    model1 = json.load(f1)

with open("inference_output_2.json") as f2:
    model2 = json.load(f2)

# Find common histograms
common_histos = set(model1.keys()) & set(model2.keys())

print(f"Found {len(common_histos)} common histograms\n")

# Compare each histogram
for name in sorted(common_histos):
    h1 = model1[name]
    h2 = model2[name]

    edges1 = np.array(h1["edges"])
    edges2 = np.array(h2["edges"])

    if not np.allclose(edges1, edges2):
        print(f"[{name}] ❌ Different bin edges!")
        continue

    contents1 = np.array(h1["contents"])
    contents2 = np.array(h2["contents"])
    diff = contents1 - contents2
    sum_diff = np.sum(np.abs(diff))
    max_bin_diff = np.max(np.abs(diff))

    # Summary
    if sum_diff < 1e-2:
        status = "✅ Identical"
    elif sum_diff < 1.0:
        status = "⚠️  Minor diff"
    else:
        status = "❗ Significant diff"

    print(f"[{name}] {status} | Δsum={sum_diff:.2f}, Max bin Δ={max_bin_diff:.2f}")

