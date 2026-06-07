#!/usr/bin/env nextflow

/*
 * Module D Walkthrough — Loading a Samplesheet
 *
 * This script shows the three steps every Nextflow pipeline uses
 * to go from a CSV file to a process-ready channel:
 *
 *   Step 1: Read the CSV → 12 Map objects
 *   Step 2: .map transforms each row → [meta, file1, file2] tuples
 *   Step 3: .view for debugging (non-consuming)
 *
 * Run:  nextflow run course/walkthroughs/module_d_samplesheet.nf
 *
 * 🔑 Key learning: .map does not change the NUMBER of items.
 *    It changes the SHAPE of each item.
 */

params.samplesheet = "${projectDir}/../../data/samplesheet.csv"

workflow {

    // ─── Step 1: splitCsv ───────────────────────────────────────────────────
    // channel.fromPath reads the file
    // .splitCsv(header: true) emits one Map per row
    // Result: 12 Map objects like [sample: 'patient1_tumor', patient: 'patient1', ...]

    println "\n── Step 1: splitCsv ─────────────────────────────────────────────────"
    println "   channel.fromPath → .splitCsv(header: true)"
    println "   Result: 12 Map objects (one per CSV row)\n"

    ch_rows = channel.fromPath(params.samplesheet, checkIfExists: true)
        .splitCsv(header: true)

    ch_rows.view { row -> "   Row: ${row.sample} | ${row.condition} | ${row.subtype}" }


    // ─── Step 2: .map — transform to tuples ─────────────────────────────────
    // Each row becomes a three-element tuple: [meta, fastq_1, fastq_2]
    //
    // Why file()? Creates a Nextflow Path object.
    // Without file(): process gets a STRING but the file is never staged.
    //                 The tool fails with "no such file".
    // With file():    Nextflow creates a symlink in the work directory.
    //                 The tool finds the file exactly where it expects.
    //
    // This is the single most common Nextflow mistake.

    println "\n── Step 2: .map to tuples ───────────────────────────────────────────"
    println "   .map { row -> [meta, file(row.fastq_1), file(row.fastq_2)] }"
    println "   Same 12 items — different SHAPE\n"

    ch_reads = ch_rows.map { row ->
        def meta = [
            id        : row.sample,
            patient   : row.patient,
            condition : row.condition,
            subtype   : row.subtype
        ]
        [ meta, file(row.fastq_1), file(row.fastq_2) ]
    }

    ch_reads.view { meta, r1, r2 ->
        "   Tuple: [${meta.id}] → ${r1.name}, ${r2.name}"
    }


    // ─── Step 3: .view for debugging ────────────────────────────────────────
    // .view does NOT consume items. The channel still emits all 12 downstream.
    // Add .view anywhere when debugging. Remove before production.

    println "\n── Step 3: .view is non-consuming ─────────────────────────────────"
    println "   The channel still has all 12 items after .view\n"
    println "   ✅ Safe to chain: ch.view{}.filter{}.view{}"
    println "   ❌ Do not leave in production — it clutters logs\n"
}
