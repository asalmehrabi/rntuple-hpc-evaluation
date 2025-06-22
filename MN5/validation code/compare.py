import json
import uproot
import numpy as np
from collections import defaultdict

def load_reference(path):
    with open(path) as f:
        return json.load(f)

def extract_histos_from_root(root_file):
    histos = defaultdict(dict)
    with uproot.open(root_file) as f:
        names = set(k.rsplit(";", 1)[0] for k in f)
        for name in names:
            h = f[name]
            histos[name]["edges"] = h.axis().edges().tolist()
            histos[name]["contents"] = h.counts(flow=True).tolist()
    return histos

def compare(reference, test, atol_minor=2.0, atol_major=10.0):
    counters = {"identical": 0, "minor": 0, "major": 0}
    for name, ref_h in reference.items():
        h = test.get(name)
        if not h or not np.allclose(h["edges"], ref_h["edges"]):
            continue
        diffs = np.abs(np.array(h["contents"]) - np.array(ref_h["contents"]))
        if np.all(diffs < 1e-6):
            counters["identical"] += 1
        elif np.all(diffs < atol_minor):
            counters["minor"] += 1
        else:
            counters["major"] += 1
    return counters

reference_file = "/home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/reference/histos_all_file_per_process.json"
reference = load_reference(reference_file)

files = {
    "baseline": "output_jet_baseline.root",
    "2 jets": "output_jet_2.root",
    "4 jets": "output_jet_4.root",
    "8 jets": "output_jet_8.root"
}

print(f"{'Model':<10} | {'Identical':^9} | {'Minor ⚠️':^9} | {'Major ❗':^9}")
print("-" * 45)
for label, path in files.items():
    histos = extract_histos_from_root(path)
    counts = compare(reference, histos)
    print(f"{label:<10} | {counts['identical']:^9} | {counts['minor']:^9} | {counts['major']:^9}")

