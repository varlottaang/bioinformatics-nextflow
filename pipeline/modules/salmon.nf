--- /home/user/nextflow-cancer-genomics-90min/pipeline/modules/salmon.nf
+++ /home/user/nextflow-cancer-genomics-90min/pipeline/modules/salmon.nf
@@ -0,0 +1,49 @@
+/*
+ * SALMON — Transcript-level quantification
+ *
+ * Biology: Maps reads to the chr17 transcriptome and estimates expression counts.
+ *          Uses quasi-mapping (no BAM produced) — much faster than traditional alignment.
+ *          Output is a count per transcript per sample.
+ *
+ * Input:  [meta, trimmed_1, trimmed_2] — cleaned reads from Fastp
+ *         salmon_index                 — pre-built index (value channel, shared)
+ * Output: [meta, quant_dir]            — directory containing quant.sf
+ *         [meta, logs]                 — alignment stats for MultiQC
+ */
+
+process SALMON {
+
+    tag { "${meta.id}" }
+
+    container 'quay.io/biocontainers/salmon:1.10.3--h6dccd9a_2'
+
+    publishDir { "${params.outdir}/salmon/${meta.id}" }, mode: 'copy'
+
+    input:
+    tuple val(meta), path(trimmed_1), path(trimmed_2)
+    path(index)
+
+    output:
+    tuple val(meta), path("${meta.id}_quant"), emit: counts
+    tuple val(meta), path("${meta.id}_meta_info.json"), emit: logs
+
+    script:
+    """
+    salmon quant \
+        --index ${index} \
+        --libType A \
+        --mates1 ${trimmed_1} \
+        --mates2 ${trimmed_2} \
+        --output ${meta.id}_quant \
+        --threads ${task.cpus} \
+        --validateMappings \
+        --gcBias

+    cp ${meta.id}_quant/aux_info/meta_info.json ${meta.id}_meta_info.json
+    """
+
+    stub:
+    """
+    mkdir -p ${meta.id}_quant/aux_info
+    echo 'transcript_id\tlength\teffective_length\tTPM\tNumReads' > ${meta.id}_quant/quant.sf
+    echo '{"num_mapped": 1000}' > ${meta.id}_quant/aux_info/meta_info.json
+    cp ${meta.id}_quant/aux_info/meta_info.json ${meta.id}_meta_info.json
+    """
+}