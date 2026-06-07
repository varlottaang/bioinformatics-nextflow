/*
 * MULTIQC — Aggregate QC report
 *
 * Biology: Collects QC metrics from all tools (Fastp adapter stats, Salmon
 *          mapping rates) into a single interactive HTML report. Allows quick
 *          identification of failed samples without inspecting each individually.
 *
 * Input:  collected list of QC files from all samples
 * Output: multiqc_report.html — single interactive report
 */

process MULTIQC {

    container 'quay.io/biocontainers/multiqc:1.35--pyhdfd78af_1'

    publishDir { "${params.outdir}/multiqc" }, mode: 'copy'

    input:
    path('*')

    output:
    path("multiqc_report.html"), emit: report
    path("multiqc_data"), emit: data

    script:
    """
    multiqc . --filename multiqc_report.html
    """

    stub:
    """
    touch multiqc_report.html
    mkdir multiqc_data
    touch multiqc_data/multiqc_general_stats.txt
    """
}
