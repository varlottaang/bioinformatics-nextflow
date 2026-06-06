--- /home/user/nextflow-cancer-genomics-90min/scripts/prepare_test_data.sh
++ /home/user/nextflow-cancer-genomics-90min/scripts/prepare_test_data.sh
@@ -0,0 +1,172 @@
#!/usr/bin/env bash
set -euo pipefail

#
# Prepare test data for the Nextflow Cancer Genomics 90-min course
#
# This script:
#   1. Downloads chr17 transcriptome from Ensembl
#   2. Builds a Salmon index (chr17 only — ~50 MB)
#   3. Simulates paired-end FASTQ files for 6 patients × tumor + normal
#
# Requirements: salmon, python3 (with numpy), gzip
# Runtime: ~5 minutes
#
# The simulated reads are intentionally small (~10,000 per sample) to keep
# the pipeline fast enough for a 2-CPU Codespace.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data"
REF_DIR="$DATA_DIR/reference"
READS_DIR="$DATA_DIR/reads"

mkdir -p "$REF_DIR" "$READS_DIR"

echo "==> Step 1: Download chr17 transcripts from Ensembl..."
TRANSCRIPTOME_URL="https://ftp.ensembl.org/pub/release-112/fasta/homo_sapiens/cdna/Homo_sapiens.GRCh38.cdna.all.fa.gz"
TRANSCRIPTOME_GZ="$REF_DIR/Homo_sapiens.GRCh38.cdna.all.fa.gz"
TRANSCRIPTOME_CHR17="$REF_DIR/chr17_transcripts.fa"

if [ ! -f "$TRANSCRIPTOME_CHR17" ]; then
    curl -L -o "$TRANSCRIPTOME_GZ" "$TRANSCRIPTOME_URL"

    echo "==> Extracting chr17 transcripts only..."
    # Keep only transcripts from chromosome 17
    python3 - "$TRANSCRIPTOME_GZ" "$TRANSCRIPTOME_CHR17" <<'PYEOF'
import gzip
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

keep = False
count = 0
with gzip.open(input_file, 'rt') as fin, open(output_file, 'w') as fout:
    for line in fin:
        if line.startswith('>'):
            # Header format: >ENST... chromosome:GRCh38:17:...
            keep = 'chromosome:GRCh38:17:' in line
            if keep:
                count += 1
        if keep:
            fout.write(line)

print(f"  Extracted {count} chr17 transcripts")
PYEOF
    rm -f "$TRANSCRIPTOME_GZ"
fi

echo "==> Step 2: Build Salmon index (chr17 only)..."
if [ ! -d "$REF_DIR/salmon_index" ]; then
    salmon index \
        --transcripts "$TRANSCRIPTOME_CHR17" \
        --index "$REF_DIR/salmon_index" \
        --threads 2 \
        -k 23
    echo "  Salmon index built."
fi

echo "==> Step 3: Simulate FASTQ reads for 6 patients..."
python3 - "$TRANSCRIPTOME_CHR17" "$READS_DIR" <<'PYEOF'
import sys
import random
import gzip
import os

random.seed(42)

transcriptome_file = sys.argv[1]
reads_dir = sys.argv[2]

# Load transcript sequences
transcripts = {}
current_id = None
current_seq = []
with open(transcriptome_file) as f:
    for line in f:
        if line.startswith('>'):
            if current_id:
                transcripts[current_id] = ''.join(current_seq)
            current_id = line.split()[0][1:]
            current_seq = []
        else:
            current_seq.append(line.strip())
if current_id:
    transcripts[current_id] = ''.join(current_seq)

# Filter to transcripts >= 200bp
transcripts = {k: v for k, v in transcripts.items() if len(v) >= 200}
tx_ids = list(transcripts.keys())
print(f"  {len(tx_ids)} transcripts available for simulation")

# Patient definitions — which genes are perturbed
patients = [
    ('patient1', 'BRCA'),
    ('patient2', 'BRCA'),
    ('patient3', 'lung'),
    ('patient4', 'lung'),
    ('patient5', 'colorectal'),
    ('patient6', 'colorectal'),
]

NUM_READS = 10000  # per sample — small for fast pipeline runtime
READ_LEN = 100

def simulate_reads(tx_dict, tx_list, n_reads, read_len):
    """Generate paired-end reads from random transcripts."""
    reads_r1 = []
    reads_r2 = []
    for i in range(n_reads):
        tx_id = random.choice(tx_list)
        seq = tx_dict[tx_id]
        if len(seq) < read_len * 2 + 50:
            # Skip very short transcripts
            tx_id = random.choice(tx_list)
            seq = tx_dict[tx_id]
        frag_len = random.randint(read_len + 50, min(len(seq), 500))
        start = random.randint(0, max(0, len(seq) - frag_len))
        fragment = seq[start:start + frag_len]

        r1 = fragment[:read_len]
        r2_rc = fragment[-read_len:]
        # Simple reverse complement
        comp = str.maketrans('ACGT', 'TGCA')
        r2 = r2_rc.translate(comp)[::-1]

        qual = 'I' * read_len  # Phred 40

        reads_r1.append(f"@read_{i}/1\n{r1}\n+\n{qual}\n")
        reads_r2.append(f"@read_{i}/2\n{r2}\n+\n{qual}\n")
    return reads_r1, reads_r2

for patient, subtype in patients:
    for condition in ['tumor', 'normal']:
        sample_id = f"{patient}_{condition}"
        r1_path = os.path.join(reads_dir, f"{sample_id}_R1.fastq.gz")
        r2_path = os.path.join(reads_dir, f"{sample_id}_R2.fastq.gz")

        if os.path.exists(r1_path):
            print(f"  {sample_id}: already exists, skipping")
            continue

        reads_r1, reads_r2 = simulate_reads(transcripts, tx_ids, NUM_READS, READ_LEN)

        with gzip.open(r1_path, 'wt') as f:
            f.writelines(reads_r1)
        with gzip.open(r2_path, 'wt') as f:
            f.writelines(reads_r2)

        print(f"  {sample_id}: {NUM_READS} read pairs written")

print("\n  ✅ All test FASTQ files generated.")
PYEOF

echo ""
echo "==> Done! Test data prepared in: $DATA_DIR"
echo "    Reference: $REF_DIR/salmon_index"
echo "    Reads:     $READS_DIR/"
echo ""
echo "    Run the pipeline:"
echo "    nextflow run pipeline/main.nf -profile docker,test"