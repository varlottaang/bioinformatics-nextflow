--- /home/user/nextflow-cancer-genomics-90min/course/demos/module_d_channels.nf
+++ /home/user/nextflow-cancer-genomics-90min/course/demos/module_d_channels.nf
@@ -0,0 +1,68 @@
+#!/usr/bin/env nextflow
+
+/*
+ * Module D — Channel Demo
+ *
+ * This script demonstrates the four key channel concepts:
+ *   1. Value channels (shared resources)
+ *   2. Queue channels from CSV (one item per row)
+ *   3. The .map operator (transform shape)
+ *   4. The .filter operator (subset items)
+ *
+ * Run:  nextflow run course/demos/module_d_channels.nf
+ */
+
+// ─── Part 1: Value channel ──────────────────────────────────────────────────
+// A value channel emits the same item every time it is read.
+// Never consumed. Used for shared resources like a reference index.
+
+println "\n━━━ Part 1: Value channel ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
+println "A value channel emits the same item repeatedly — never consumed.\n"
+
+ch_index = channel.value('data/reference/salmon_index')
+ch_index.view { v -> "  Value channel emits: ${v}" }
+
+
+// ─── Part 2: Queue channel from CSV ─────────────────────────────────────────
+// Each row becomes one item. Items are consumed — each emitted once.
+
+workflow {
+
+    println "\n━━━ Part 2: Raw CSV rows (queue channel) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
+    println "Each row is a Map object with column headers as keys.\n"
+
+    ch_raw = channel.fromPath("${projectDir}/../../data/samplesheet.csv")
+        .splitCsv(header: true)
+
+    ch_raw.view { row -> "  Row: sample=${row.sample}, condition=${row.condition}, patient=${row.patient}" }
+
+
+    // ─── Part 3: .map transforms each item ──────────────────────────────────
+    // Same 12 items, new shape: [meta, file1, file2]
+
+    println "\n━━━ Part 3: After .map — structured tuples ━━━━━━━━━━━━━━━━━━━━━━━━━"
+    println "12 items → 12 items (map transforms, does not filter)\n"
+
+    ch_tuples = ch_raw.map { row ->
+        def meta = [
+            id        : row.sample,
+            patient   : row.patient,
+            condition : row.condition,
+            subtype   : row.subtype
+        ]
+        [ meta, row.fastq_1, row.fastq_2 ]
+    }
+
+    ch_tuples.view { meta, r1, r2 -> "  [${meta.id}] patient=${meta.patient} condition=${meta.condition}" }
+
+
+    // ─── Part 4: .filter keeps matching items ───────────────────────────────
+    // Keeps only tumor samples — 6 out of 12
+
+    println "\n━━━ Part 4: After .filter — tumor samples only ━━━━━━━━━━━━━━━━━━━━━━"
+    println "12 items → 6 items (only condition == 'tumor')\n"
+
+    ch_tumor_only = ch_tuples.filter { meta, r1, r2 -> meta.condition == 'tumor' }
+
+    ch_tumor_only.view { meta, r1, r2 -> "  [TUMOR] ${meta.id} (${meta.subtype})" }
+}