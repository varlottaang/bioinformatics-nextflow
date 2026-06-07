/*
 * FASTP — Read quality trimming and adapter removal
 *
 * Biology: Removes low-quality bases and adapter sequences from raw FASTQ reads.
 *          Clean reads improve mapping rates and reduce false-positive variants.
 *
 * Input:  [meta, fastq_1, fastq_2] — raw paired-end reads from the samplesheet
 * Output: [meta, trimmed_1, trimmed_2] — cleaned reads for Salmon
 *         [meta, json]                 — QC stats for MultiQC
 */

process FASTP {

    tag { "${meta.id}" }

    container 'community.wave.seqera.io/library/fastp:1.1.0--08aa7c5662a30d57'

    publishDir { "${params.outdir}/fastp/${meta.id}" }, mode: 'copy'

    input:
    tuple val(meta), path(fastq_1), path(fastq_2)

    output:
    tuple val(meta), path("${meta.id}_R1_trimmed.fastq.gz"), path("${meta.id}_R2_trimmed.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}_fastp.json"), emit: json

    script:
    """
    fastp \\
        --in1 ${fastq_1} \\
        --in2 ${fastq_2} \\
        --out1 ${meta.id}_R1_trimmed.fastq.gz \\
        --out2 ${meta.id}_R2_trimmed.fastq.gz \\
        --json ${meta.id}_fastp.json \\
        --html ${meta.id}_fastp.html \\
        --thread ${task.cpus} \\
        --detect_adapter_for_pe
    """

    stub:
    """
    echo "" | gzip > ${meta.id}_R1_trimmed.fastq.gz
    echo "" | gzip > ${meta.id}_R2_trimmed.fastq.gz
    echo '{"summary": {"before_filtering": {"total_reads": 1000}}}' > ${meta.id}_fastp.json
    """
}
