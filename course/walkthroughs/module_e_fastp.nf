--- /home/user/nextflow-cancer-genomics-90min/course/walkthroughs/module_e_fastp.nf
+++ /home/user/nextflow-cancer-genomics-90min/course/walkthroughs/module_e_fastp.nf
@@ -0,0 +1,107 @@
+#!/usr/bin/env nextflow
+
+/*
+ * Module E Walkthrough — The Fastp Process
+ *
+ * This script isolates the FASTP process so you can study its anatomy:
+ *   - tag: names each task in the log
+ *   - container: which Docker image to use
+ *   - publishDir: where to copy results
+ *   - input: what the process receives (tuple from channel)
+ *   - output: what it produces (with emit labels)
+ *   - script: the shell command that runs inside the container
+ *   - stub: fake outputs for testing without running the real tool
+ *
+ * Run (stub):  nextflow run course/walkthroughs/module_e_fastp.nf -stub
+ * Run (real):  nextflow run course/walkthroughs/module_e_fastp.nf -profile docker
+ *
+ * 🔑 Key learning: A process is a self-contained unit.
+ *    It knows nothing about the rest of the pipeline.
+ *    Channels deliver data IN. Channels carry data OUT.
+ */
+
+params.samplesheet = "${projectDir}/../../data/samplesheet.csv"
+params.outdir      = "${projectDir}/../../results"
+
+// ─── The process ────────────────────────────────────────────────────────────
+
+process FASTP {
+
+    // tag: labels each task execution in the Nextflow log
+    // Without it: "FASTP (1)", "FASTP (2)" — not helpful
+    // With it:    "FASTP (patient1_tumor)" — immediately clear which sample
+    tag { "${meta.id}" }
+
+    // container: this process runs inside this Docker image
+    // Every process can use a DIFFERENT container — complete isolation
+    container 'quay.io/biocontainers/fastp:0.23.4--hadf994f_0'
+
+    // publishDir: copy outputs here when the task succeeds
+    // The closure { } is required in Nextflow 26 when referencing input variables
+    publishDir { "${params.outdir}/fastp/${meta.id}" }, mode: 'copy'
+
+    // input: what the process RECEIVES from its input channel
+    // This must match the shape of ch_reads: [meta, fastq_1, fastq_2]
+    input:
+    tuple val(meta), path(fastq_1), path(fastq_2)
+
+    // output: what the process PRODUCES
+    // emit labels let the workflow refer to specific outputs:
+    //   FASTP.out.reads → trimmed FASTQs
+    //   FASTP.out.json  → QC metrics for MultiQC
+    output:
+    tuple val(meta), path("${meta.id}_trimmed_R1.fastq.gz"), path("${meta.id}_trimmed_R2.fastq.gz"), emit: reads
+    tuple val(meta), path("${meta.id}_fastp.json"), emit: json
+    tuple val(meta), path("${meta.id}_fastp.html"), emit: html
+
+    // script: the shell command that runs INSIDE the container
+    // Variables like ${meta.id} are resolved by Nextflow before the script runs
+    // The container provides the `fastp` binary — you never install it yourself
+    script:
+    """
+    fastp \
+        --in1 ${fastq_1} \
+        --in2 ${fastq_2} \
+        --out1 ${meta.id}_trimmed_R1.fastq.gz \
+        --out2 ${meta.id}_trimmed_R2.fastq.gz \
+        --json ${meta.id}_fastp.json \
+        --html ${meta.id}_fastp.html \
+        --thread ${task.cpus} \
+        --qualified_quality_phred 20 \
+        --length_required 36
+    """
+
+    // stub: creates fake outputs instantly (no real tool execution)
+    // Used with: nextflow run ... -stub
+    // Purpose: test the pipeline structure without running heavy tools
+    stub:
+    """
+    touch ${meta.id}_trimmed_R1.fastq.gz
+    touch ${meta.id}_trimmed_R2.fastq.gz
+    echo '{}' > ${meta.id}_fastp.json
+    touch ${meta.id}_fastp.html
+    """
+}
+
+// ─── Workflow: build channel, run process ────────────────────────────────────
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
+            [ meta, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true) ]
+        }
+
+    // 12 items in the channel → FASTP fires 12 times, automatically
+    FASTP(ch_reads)
+
+    // Observe the outputs
+    FASTP.out.reads.view { meta, r1, r2 -> "  ✅ Trimmed: ${meta.id}" }
+}