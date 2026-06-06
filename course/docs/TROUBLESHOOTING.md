--- /home/user/nextflow-cancer-genomics-90min/course/docs/TROUBLESHOOTING.md
++ /home/user/nextflow-cancer-genomics-90min/course/docs/TROUBLESHOOTING.md
@@ -0,0 +1,146 @@
# Troubleshooting Guide

Common issues and their fixes. Check here before asking for help.

---

## Issue: `Script compilation failed — Invalid process definition`

**Cause:** Nextflow 26 strict syntax violation. Always one of three things:

| Missing | Fix |
|---------|-----|
| `tag` not in closure | Change `tag "${meta.id}"` → `tag { "${meta.id}" }` |
| `publishDir` not in closure | Change `publishDir "${params.outdir}"` → `publishDir { "${params.outdir}" }` |
| `script:` label missing | Add `script:` before the triple-quote block |

---

## Issue: `No such file or directory` inside a process

**Cause:** You passed a string instead of a `file()` object in `.map {}`.

```groovy
// WRONG — string, never staged
[ meta, row.fastq_1, row.fastq_2 ]

// CORRECT — Path object, Nextflow stages it
[ meta, file(row.fastq_1), file(row.fastq_2) ]
```

---

## Issue: `Process SALMON hangs — only 1 of 12 completes`

**Cause:** The Salmon index is in a queue channel instead of a value channel.
A queue channel emits once and is consumed. The first SALMON task takes it;
the other 11 wait forever.

```groovy
// WRONG — queue channel
ch_index = channel.fromPath(params.salmon_index)

// CORRECT — value channel, shared by all tasks
ch_index = channel.value(file(params.salmon_index))
```

---

## Issue: Docker not available / `Cannot connect to Docker daemon`

**In Codespaces:**
```bash
# Check Docker is running
docker ps
# If it fails, restart the Codespace (Ctrl+Shift+P → "Codespaces: Rebuild Container")
```

**On Mac/Windows:**
- Ensure Docker Desktop is running (check the whale icon in system tray)
- Docker Desktop → Settings → Resources → ensure at least 4 GB RAM allocated

---

## Issue: `disk space` errors in Codespaces

Codespaces free tier provides ~32 GB. The pipeline work directories can accumulate.

```bash
# Check usage
df -h

# Clean Nextflow work directories
rm -rf work/ .nextflow/

# Nuclear option: clean all Docker images and rebuild
docker system prune -af
```

---

## Issue: `Nextflow version requirement not met`

The pipeline requires Nextflow 26.04+. Check your version:

```bash
nextflow -version
```

If older:
```bash
# Update Nextflow
nextflow self-update
# Or install specific version
export NXF_VER=26.04.0
curl -fsSL https://get.nextflow.io | bash
```

---

## Issue: Stub run shows wrong task count

**Expected:** 31 tasks (12 FASTP + 12 SALMON + 6 DESEQ2 + 1 MULTIQC)

If you see fewer:
- Check `data/samplesheet.csv` has all 12 rows (+ header = 13 lines)
- Check file paths in the CSV are correct relative to where you run `nextflow`

```bash
wc -l data/samplesheet.csv
# Expected: 13
```

---

## Issue: `permission denied` on scripts

```bash
chmod +x scripts/prepare_test_data.sh
chmod +x .devcontainer/post-create.sh
```

---

## Issue: MultiQC report is empty or missing modules

MultiQC looks for specific file patterns. Ensure:
- Fastp JSON files end in `_fastp.json`
- Salmon `meta_info.json` is in the expected path

```bash
# Check what MultiQC found
cat results/multiqc/multiqc_data/multiqc_general_stats.txt
```

---

## Still stuck?

1. Check the Nextflow log: `cat .nextflow.log | tail -100`
2. Check the failed task: `cat work/<hash>/<hash>/.command.err`
3. Run with debug output: `nextflow run ... -dump-channels`
4. Clean everything and retry:
   ```bash
   rm -rf work/ .nextflow/ results/
   nextflow run pipeline/main.nf -profile docker,test -stub
   ```