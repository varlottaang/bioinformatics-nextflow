--- /home/user/nextflow-cancer-genomics-90min/pipeline/main.nf
++ /home/user/nextflow-cancer-genomics-90min/pipeline/main.nf
@@ -0,0 +1,90 @@
#!/usr/bin/env nextflow

/*
 * Nextflow Cancer Genomics — 90-Minute Introduction
 * RNA-seq Differential Expression Pipeline
 *
 * Pipeline: FASTQ → Fastp → Salmon → DESeq2 → MultiQC
 * Dataset:  6 patients × tumor + normal (chr17)
 *
 * This pipeline is designed for teaching. It is structurally identical
 * to production RNA-seq pipelines but uses a small dataset that runs
 * in under 5 minutes on a 2-CPU Codespace.
 */

nextflow.preview.output = true

// ─── Parameters ─────────────────────────────────────────────────────────────

params.samplesheet  = "${projectDir}/../data/samplesheet.csv"
params.salmon_index = "${projectDir}/../data/reference/salmon_index"
params.transcript_to_gene = "${projectDir}/../data/reference/tx2gene.tsv"
params.outdir       = "${projectDir}/../results"

// ─── Include modules ────────────────────────────────────────────────────────

include { FASTP  } from './modules/fastp'
include { SALMON } from './modules/salmon'
include { DESEQ2 } from './modules/deseq2'
include { MULTIQC } from './modules/multiqc'

// ─── Main workflow ──────────────────────────────────────────────────────────

workflow {

    // --- Load samplesheet and build the reads channel ---
    ch_samplesheet = channel.fromPath(params.samplesheet, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id        : row.sample,
                patient   : row.patient,
                condition : row.condition,
                subtype   : row.subtype
            ]
            [ meta, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true) ]
        }

    // --- Shared resources as value channels ---
    ch_index  = channel.value(file(params.salmon_index, checkIfExists: true))
    ch_tx2gene = channel.value(file(params.transcript_to_gene, checkIfExists: true))

    // --- Step 1: Quality trimming ---
    FASTP(ch_samplesheet)

    // --- Step 2: Quantification ---
    SALMON(FASTP.out.reads, ch_index)

    // --- Step 3: Differential expression (per patient) ---
    // Group tumor + normal by patient → 6 groups of 2
    ch_counts_grouped = SALMON.out.counts
        .map { meta, quant_dir ->
            [ meta.patient, meta, quant_dir ]
        }
        .groupTuple(by: 0)
        .map { patient, metas, quant_dirs ->
            def group_meta = [id: patient, patient: patient, subtype: metas[0].subtype]
            [ group_meta, metas, quant_dirs ]
        }

    DESEQ2(ch_counts_grouped, ch_tx2gene)

    // --- Step 4: QC report ---
    ch_multiqc_files = FASTP.out.json
        .map { meta, json -> json }
        .collect()
        .mix(
            SALMON.out.logs
                .map { meta, logs -> logs }
                .collect()
        )
        .collect()

    MULTIQC(ch_multiqc_files)
}

// ─── Output block (Nextflow 26.04+) ─────────────────────────────────────────
// Uncomment the block below on Nextflow 26.04+ for structured output publishing.

 output {
     directory params.outdir
 }