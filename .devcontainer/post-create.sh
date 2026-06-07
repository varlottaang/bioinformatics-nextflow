#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Nextflow ${NXF_VER:-26.04.0}..."
export NXF_VER=${NXF_VER:-26.04.0}
curl -fsSL https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
sudo chmod +x /usr/local/bin/nextflow

echo "==> Verifying Nextflow installation..."
nextflow -version

echo "==> Pre-pulling lightweight containers for the course..."
# Pull only the containers used by the pipeline — all are small
docker pull quay.io/biocontainers/fastp:0.23.4--hadf994f_0 &
docker pull quay.io/biocontainers/salmon:1.10.3--h6dccd9a_2 &
docker pull quay.io/biocontainers/pydeseq2:0.4.11--pyhdfd78af_0 &
docker pull quay.io/biocontainers/multiqc:1.25.2--pyhdfd78af_0 &
wait

echo "==> Preparing test data (salmon index + simulated reads)..."
cd /workspaces/$(basename "$PWD") 2>/dev/null || cd "$PWD"
bash scripts/prepare_test_data.sh

echo "==> Running stub check to verify pipeline..."
nextflow run pipeline/main.nf -profile docker,test -stub

echo ""
echo "✅ Environment ready. All 31 stub tasks should have completed."
echo "   Run 'nextflow run pipeline/main.nf -profile docker,test' for the full pipeline."
