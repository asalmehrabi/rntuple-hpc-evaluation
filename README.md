# RNTuple HPC Evaluation

This repository accompanies the Bachelor's Thesis **"Evaluating the RNTuple Performance on HPC Systems"**, which explores the performance of the [RNTuple](https://root.cern/doc/master/classROOT_1_1Experimental_1_1RNTuple.html) I/O format in modern High-Performance Computing (HPC) environments.

---

## Abstract

As data from CERN's Large Hadron Collider grows, leveraging High-Performance Computing (HPC) systems and advanced data formats such as RNTuple has become essential for High-Energy Physics (HEP) analyses and AI workflows.  
This thesis evaluates RNTuple performance on modern HPC systems by analyzing how storage configurations, parallelization strategies, and distributed executions affect traditional event analyses and machine learning pipelines. Benchmarks are performed using real-world datasets from the [Analysis Grand Challenge (AGC)](https://github.com/root-project/analysis-grand-challenge), a representative HEP use case.

---

## Prerequisites

To successfully run the experiments in this repository, the following setup is required **on each HPC system (LUMI, Eiger, MareNostrum 5)**:

1. ### 🔐 Access to HPC systems
   - Valid user credentials and project access for:
     - **LUMI** (CSC Finland)
     - **Eiger** (CSCS Switzerland)
     - **MareNostrum 5** at BSC (GPP partition used)

2. ### 📦 Clone AGC Repository
   On each system, clone the official [Analysis Grand Challenge](https://github.com/root-project/analysis-grand-challenge):
   ```bash
   git clone https://github.com/root-project/analysis-grand-challenge.git

## Repository Structure

rntuple-hpc-evaluation/
├── LUMI/       # Launcher scripts for LUMI (CSC Finland)
│               # Also includes modified AGC analysis.py for distributed RDataFrame using Dask queue
├── EIGER/      # Launcher scripts for Eiger (CSCS Switzerland)
├── MN5/        # Launcher scripts for MareNostrum 5 (BSC Spain), GPP partition
│               # Also includes validation code and metrics processing
├── performance_analysis.ipynb  # Jupyter notebook for analyzing performance results

