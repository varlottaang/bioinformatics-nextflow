# Lesson Commands — Quick Reference

Keep this open on a second screen during the lesson. Every command you will run
is listed here in order with its expected output.

---

## Pre-lesson verification

```bash
# Confirm Nextflow works
nextflow -version
# Expected: nextflow version 26.04.x

# Confirm Docker images
docker images | grep biocontainers
# Expected: 4 images (fastp, salmon, pydeseq2, multiqc)

# Stub check
nextflow run pipeline/main.nf -profile docker,test -stub
# Expected: 31 tasks COMPLETED
```

---

## Module C — Demo: Environment tour

```bash
# Repository layout
tree -L 2

# Show the samplesheet
cat data/samplesheet.csv

# Stub run (if not already done in pre-check)
nextflow run pipeline/main.nf -profile docker,test -stub

# Show a work directory
ls work/
ls work/<pick-a-hash>/<pick-a-hash>/
cat work/<pick-a-hash>/<pick-a-hash>/.command.sh

# Preview results directories (do not open files yet)
ls results/deseq2/
ls results/multiqc/
```

---

## Module D — Demo: Channels

```bash
# Run the channel demo
nextflow run course/demos/module_d_channels.nf
```

**Expected output:** Four sections showing value channel, raw CSV rows,
mapped tuples, and filtered tumor-only items.

---

## Module D — Walkthrough: Samplesheet loading

```bash
# Run the samplesheet walkthrough
nextflow run course/walkthroughs/module_d_samplesheet.nf
```

**Expected output:** Three steps showing splitCsv, .map transformation,
and .view debugging output.

---

## Module E — Walkthrough: Fastp process

```bash
# Run in stub mode first (instant)
nextflow run course/walkthroughs/module_e_fastp.nf -stub

# Then show the real execution (optional, ~1 min)
nextflow run course/walkthroughs/module_e_fastp.nf -profile docker
```

**Expected output (stub):** 12 tasks complete, each tagged with sample ID.

**After stub:** Show the work directory structure:
```bash
ls work/<hash>/<hash>/
cat work/<hash>/<hash>/.command.sh
cat work/<hash>/<hash>/.command.err
```

---

## Module F — The biological payoff

```bash
# Open the MultiQC report
# (In Codespaces, right-click → Open with Live Server, or use the port forward)
open results/multiqc/multiqc_report.html

# Show a DESeq2 result
cat results/deseq2/patient1/patient1_de_results.tsv | head -20

# Show the volcano plot
open results/deseq2/patient1/patient1_volcano.png
```

---

## Troubleshooting commands

```bash
# Clear all cached work and try again
rm -rf work/ .nextflow/
nextflow run pipeline/main.nf -profile docker,test -stub

# Check Docker is running
docker ps

# Check disk space (Codespaces can fill up)
df -h

# Show Nextflow log for last run
cat .nextflow.log | tail -50
```