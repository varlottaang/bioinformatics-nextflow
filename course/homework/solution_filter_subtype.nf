--- /home/user/nextflow-cancer-genomics-90min/course/homework/solution_filter_subtype.nf
+++ /home/user/nextflow-cancer-genomics-90min/course/homework/solution_filter_subtype.nf
@@ -0,0 +1,122 @@
+#!/usr/bin/env nextflow
+
+/*
+ * 🏠 Homework SOLUTION — Filter by Subtype
+ *
+ * The single line that solves it:
+ *   ch_reads = ch_reads.filter { meta, r1, r2 -> meta.subtype == 'BRCA' }
+ *
+ * Result: 4 FASTP + 4 SALMON + 2 DESEQ2 + 1 MULTIQC = 11 tasks
+ */
+
+params.samplesheet = "${projectDir}/../../data/samplesheet.csv"
+params.salmon_index = "${projectDir}/../../data/reference/salmon_index"
+params.transcript_to_gene = "${projectDir}/../../data/reference/tx2gene.tsv"
+params.outdir = "${projectDir}/../../results_homework"
+
+process FASTP {
+    tag { "${meta.id}" }
+    input:
+    tuple val(meta), path(fastq_1), path(fastq_2)
+    output:
+    tuple val(meta), path("${meta.id}_R1.fq.gz"), path("${meta.id}_R2.fq.gz"), emit: reads
+    tuple val(meta), path("${meta.id}.json"), emit: json
+    stub:
+    """
+    touch ${meta.id}_R1.fq.gz ${meta.id}_R2.fq.gz
+    echo '{}' > ${meta.id}.json
+    """
+    script:
+    """
+    touch ${meta.id}_R1.fq.gz ${meta.id}_R2.fq.gz
+    echo '{}' > ${meta.id}.json
+    """
+}
+
+process SALMON {
+    tag { "${meta.id}" }
+    input:
+    tuple val(meta), path(trimmed_1), path(trimmed_2)
+    path(index)
+    output:
+    tuple val(meta), path("${meta.id}_quant"), emit: counts
+    stub:
+    """
+    mkdir -p ${meta.id}_quant/aux_info
+    echo 'Name\tLength\tEffectiveLength\tTPM\tNumReads' > ${meta.id}_quant/quant.sf
+    echo '{}' > ${meta.id}_quant/aux_info/meta_info.json
+    """
+    script:
+    """
+    mkdir -p ${meta.id}_quant/aux_info
+    echo 'Name\tLength\tEffectiveLength\tTPM\tNumReads' > ${meta.id}_quant/quant.sf
+    echo '{}' > ${meta.id}_quant/aux_info/meta_info.json
+    """
+}
+
+process DESEQ2 {
+    tag { "${group_meta.id}" }
+    input:
+    tuple val(group_meta), val(metas), path(quant_dirs)
+    output:
+    tuple val(group_meta), path("${group_meta.id}_results.tsv"), emit: results
+    stub:
+    """
+    echo -e "gene\tLFC\tpadj" > ${group_meta.id}_results.tsv
+    """
+    script:
+    """
+    echo -e "gene\tLFC\tpadj" > ${group_meta.id}_results.tsv
+    """
+}
+
+process MULTIQC {
+    input:
+    path('*')
+    output:
+    path("multiqc_report.html")
+    stub:
+    """
+    touch multiqc_report.html
+    """
+    script:
+    """
+    touch multiqc_report.html
+    """
+}
+
+workflow {
+
+    ch_reads = channel.fromPath(params.samplesheet, checkIfExists: true)
+        .splitCsv(header: true)
+        .map { row ->
+            def meta = [
+                id        : row.sample,
+                patient   : row.patient,
+                condition : row.condition,
+                subtype   : row.subtype
+            ]
+            [ meta, file(row.fastq_1), file(row.fastq_2) ]
+        }
+
+    // ✅ SOLUTION: filter to keep only BRCA patients
+    ch_reads = ch_reads.filter { meta, r1, r2 -> meta.subtype == 'BRCA' }
+
+    ch_index = channel.value(file(params.salmon_index))
+
+    FASTP(ch_reads)
+    SALMON(FASTP.out.reads, ch_index)
+
+    ch_grouped = SALMON.out.counts
+        .map { meta, quant_dir -> [ meta.patient, meta, quant_dir ] }
+        .groupTuple(by: 0)
+        .map { patient, metas, quant_dirs ->
+            def group_meta = [id: patient, patient: patient, subtype: metas[0].subtype]
+            [ group_meta, metas, quant_dirs ]
+        }
+
+    DESEQ2(ch_grouped)
+
+    ch_qc = FASTP.out.json.map { meta, json -> json }.collect()
+    MULTIQC(ch_qc)
+}