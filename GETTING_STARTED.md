# Getting Started

## Three setup paths

Choose ONE of the following. Path 1 is recommended — it requires zero local setup.

---

### Path 1: GitHub Codespaces (recommended)

1. Click the green **Code** button on the repository page
2. Select **Codespaces** → **Create codespace on main**
3. Wait 3–5 minutes for the environment to build
4. When the terminal says `✅ Environment ready`, you are done

**Requirements:** A GitHub account (free tier is sufficient — you get 60 hours/month)

---

### Path 2: Local with Docker

**Requirements:** Docker Desktop, Java 17+, 8 GB free disk space

```bash
# 1. Clone the repository
git clone https://github.com/<your-org>/nextflow-cancer-genomics-90min.git
cd nextflow-cancer-genomics-90min

# 2. Install Nextflow (if not already installed)
curl -fsSL https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# 3. Verify
nextflow -version          # should show 26.04.x
docker --version           # should show Docker 24+

# 4. Pull container images (~800 MB total)
docker pull quay.io/biocontainers/fastp:0.23.4--hadf994f_0
docker pull quay.io/biocontainers/salmon:1.10.3--h6dccd9a_2
docker pull quay.io/biocontainers/pydeseq2:0.4.11--pyhdfd78af_0
docker pull quay.io/biocontainers/multiqc:1.25.2--pyhdfd78af_0

# 5. Run stub check
nextflow run pipeline/main.nf -profile docker,test -stub
# Expected: 31 tasks COMPLETED
```

---

### Path 3: Local with Conda (no Docker)

**Requirements:** Conda/Mamba, Java 17+

```bash
# 1. Clone
git clone https://github.com/<your-org>/nextflow-cancer-genomics-90min.git
cd nextflow-cancer-genomics-90min

# 2. Install Nextflow
curl -fsSL https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# 3. Create conda environment
conda env create -f environment.yml
conda activate nf-cancer-course

# 4. Run stub check
nextflow run pipeline/main.nf -profile test -stub
```

---

## Verify your setup

Regardless of which path you chose, run:

```bash
nextflow run pipeline/main.nf -profile docker,test -stub
```

You should see:
```
executor >  local (31)
[xx/yyyyyy] FASTP (patient1_tumor)     [100%] 12 of 12 ✔
[xx/yyyyyy] SALMON (patient1_tumor)    [100%] 12 of 12 ✔
[xx/yyyyyy] DESEQ2 (patient1)          [100%] 6 of 6 ✔
[xx/yyyyyy] MULTIQC                    [100%] 1 of 1 ✔
```

If any step fails, see `course/docs/TROUBLESHOOTING.md`.

---

## What to bring to class

- This environment running and verified
- A web browser for viewing HTML reports
- Curiosity about cancer genomics

That's it. Every file you need is already in the repository.