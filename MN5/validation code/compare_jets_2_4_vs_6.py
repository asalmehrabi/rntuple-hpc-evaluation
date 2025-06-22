import json
import numpy as np

def load_json(path):
    with open(path) as f:
        return json.load(f)

def compare_histos(reference, target, eps_minor=1.0, eps_major=10.0):
    common = set(reference.keys()) & set(target.keys())
    results = {"identical": 0, "minor": 0, "major": 0, "total": len(common)}

    for name in common:
        ref = np.array(reference[name]["contents"])
        tgt = np.array(target[name]["contents"])
        delta_sum = float(np.sum(np.abs(ref - tgt)))

        if delta_sum < eps_minor:
            results["identical"] += 1
        elif delta_sum < eps_major:
            results["minor"] += 1
        else:
            results["major"] += 1

    return results

# load json
histo_2 = load_json("json_jet_2.json")
histo_4 = load_json("json_jet_4.json")
histo_6 = load_json("json_jet_baseline.json")  # baseline

# Compare with baseline
cmp_2_vs_6 = compare_histos(histo_6, histo_2)
cmp_4_vs_6 = compare_histos(histo_6, histo_4)

# show results
print("=== Comparison Summary ===\n")
print(f"{'Comparison':<15} | {'Total':<5} | {'✅ Identical':<10} | {'⚠️ Minor':<7} | {'❗ Major':<7}")
print("-" * 55)
for label, cmp in [("2 vs 6", cmp_2_vs_6), ("4 vs 6", cmp_4_vs_6)]:
    print(f"{label:<15} | {cmp['total']:<5} | {cmp['identical']:<10} | {cmp['minor']:<7} | {cmp['major']:<7}")

