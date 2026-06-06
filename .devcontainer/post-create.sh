--- /home/user/nextflow-cancer-genomics-90min/.devcontainer/post-create.sh
+++ /home/user/nextflow-cancer-genomics-90min/.devcontainer/post-create.sh
@@ -0,0 +1,21 @@
+#!/usr/bin/env bash
+set -euo pipefail
+
+echo "==> Verifying Nextflow installation..."
+nextflow -version
+
+echo "==> Pre-pulling lightweight containers for the course..."
+# Pull only the containers used by the pipeline — all are small
+docker pull quay.io/biocontainers/fastp:0.23.4--hadf994f_0 &
+docker pull quay.io/biocontainers/salmon:1.10.3--h6dccd9a_2 &
+docker pull quay.io/biocontainers/pydeseq2:0.4.11--pyhdfd78af_0 &
+docker pull quay.io/biocontainers/multiqc:1.25.2--pyhdfd78af_0 &
+wait
+
+echo "==> Running stub check to verify pipeline..."
+cd /workspaces/$(basename "$PWD") 2>/dev/null || cd "$PWD"
+nextflow run pipeline/main.nf -profile docker,test -stub
+
+echo ""
+echo "✅ Environment ready. All 31 stub tasks should have completed."
+echo "   Run 'nextflow run pipeline/main.nf -profile docker,test' for the full pipeline."