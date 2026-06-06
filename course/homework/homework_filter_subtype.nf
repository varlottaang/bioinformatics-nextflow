--- /home/user/nextflow-cancer-genomics-90min/course/homework/homework_filter_subtype.nf
+++ /home/user/nextflow-cancer-genomics-90min/course/homework/homework_filter_subtype.nf
@@ -0,0 +1,142 @@
+#!/usr/bin/env nextflow
+
+/*
+ * 🏠 Homework Exercise — Filter by Subtype
+ *
+ * GOAL: Modify this pipeline to process ONLY breast cancer (BRCA) patients.
+ *
+ * Currently it processes all 6 patients (12 samples).
+ * After your modification: only 2 patients (4 samples) should run.
+ *
+ * INSTRUCTIONS:
+ *   1. Find the place where ch_reads is created (after .map)
+ *   2. Add a .filter { } operator to keep only BRCA samples
+ *   3. Run with -stub to verify: you should see 4 FASTP + 4 SALMON + 2 DESEQ2 + 1 MULTIQC = 11 tasks
+ *
+ * HINTS:
+ *   - Review course/demos/module_d_channels.nf Part 4 for .filter syntax
+ *   - The meta map contains a 'subtype' field
+ *   - .filter goes BETWEEN .map and FASTP(ch_reads)
+ *
+ * RUN:    nextflow run course/homework/homework_filter_subtype.nf -stub
+ * VERIFY: Task count should be 11, not 31
+ */
+
+params.samplesheet = "${projectDir}/../../data/samplesheet.csv"
+params.salmon_index = "${projectDir}/../../data/reference/salmon_index"
+params.transcript_to_gene = "${projectDir}/../../data/reference/tx2gene.tsv"
+params.outdir = "${projectDir}/../../results_homework"
+
+// ─── Processes (simplified for homework) ────────────────────────────────────
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
+// ─── Workflow ────────────────────────────────────────────────────────────────
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
+    // ╔══════════════════════════════════════════════════════════════════════╗
+    // ║  YOUR CODE HERE                                                     ║
+    // ║  Add a .filter { } to keep only BRCA samples                       ║
+    // ║  Example: ch_reads = ch_reads.filter { meta, r1, r2 -> ??? }       ║
+    // ╚══════════════════════════════════════════════════════════════════════╝
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