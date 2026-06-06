# Nextflow for Cancer Genomics — 90-Minute Introduction

An introductory lesson on bioinformatics using a real RNA-seq differential expression
pipeline built with Nextflow. Designed for researchers, graduate students, and
professionals who want to understand how computational pipelines work in cancer
genomics.

## What you will learn

- What bioinformatics is and why it needs automated pipelines
- The Omics landscape and RNA-seq in cancer research
- Nextflow's three building blocks: processes, channels, workflows
- How to read, run, and debug a real pipeline
- How differential expression identifies cancer-related genes

## The pipeline

```
FASTQ files (6 patients × tumor + normal)
    │
    ├── Fastp ──── quality trimming
    │
    ├── Salmon ─── transcript quantification (chr17)
    │
    ├── DESeq2 ─── differential expression (tumor vs normal)
    │
    └── MultiQC ── aggregate QC report
```

Dataset: Chromosome 17 from 6 patients across 3 cancer subtypes (BRCA, lung,
colorectal). Genes of interest: **BRCA1** and **TP53**.

## Repository structure

```
├── .devcontainer/     # GitHub Codespaces configuration
├── pipeline/          # The Nextflow pipeline (portable — take it with you)
│   ├── main.nf
│   ├── nextflow.config
│   └── modules/       # fastp.nf, salmon.nf, deseq2.nf, multiqc.nf
├── data/              # Samplesheet and reference data
├── course/            # Teaching material
│   ├── demos/         # Instructor demo scripts
│   ├── walkthroughs/  # Annotated code walkthroughs
│   ├── homework/      # Take-home exercise
│   └── docs/          # Lesson commands, troubleshooting
├── results/           # Pre-computed results for Module F
├── GETTING_STARTED.md # Student setup instructions
└── README.md          # This file
```

## Quick start

```bash
# In a Codespace or local environment with Docker:
nextflow run pipeline/main.nf -profile docker,test -stub
```

See [GETTING_STARTED.md](GETTING_STARTED.md) for full setup instructions.

## Lesson structure (90 minutes)

| Module | Topic | Duration |
|--------|-------|----------|
| A | Bioinformatics today — the Omics landscape in cancer | 15 min |
| B | What is Nextflow — building blocks and why it exists | 15 min |
| C | The biological story and reading the pipeline | 15 min |
| D | Channels — demo and walkthrough | 25 min |
| E | Processes — the Fastp walkthrough | 15 min |
| F | The biological payoff and homework | 5 min |

## Requirements

- GitHub account (for Codespaces) OR Docker Desktop + Java 17+
- No prior Nextflow experience required
- Basic command-line familiarity helpful

## License

This course material is released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Pipeline code is released under the MIT License.