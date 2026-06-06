# Instructor Guide
## Nextflow for Cancer Genomics — 90-Minute Introduction
### RNA-seq Differential Expression

---

## How to read this guide

| Icon | Type | Description |
|------|------|-------------|
| 🧬 | **Biology snippet** | Short explanation of a biological concept. Pre-written speaker notes. |
| 👁️ | **Demo** | You run pre-written code. Learners watch and listen. |
| 📖 | **Walkthrough** | You open a file, read through it with learners, then run it. |
| 🏠 | **Homework** | Take-home exercise. Introduced at the end of the lesson. |

**Golden rules:**
- No live coding. Every file is already written and tested.
- Biology snippets end with: *"that is why the next step in our pipeline does X."*
- Keep `course/docs/LESSON_COMMANDS.md` open on a second screen throughout.
- Run the stub check the day before to confirm everything works.

---

## Nextflow 26 — three rules to mention during walkthroughs

This repository targets Nextflow 26+. Three syntax rules differ from older versions.
Point them out explicitly when they appear during walkthroughs — students will encounter
them when they write their own code.

| Rule | What changed | Example |
|------|-------------|---------|
| `tag` and `publishDir` referencing input variables | Must use a closure `{ }` | `tag { "${meta.id}" }` |
| `script:` label | Required when `input:` or `output:` sections exist | `script:` before `"""` |
| Channel factories | Lowercase `channel` not `Channel` | `channel.fromPath(...)` |

If a student gets `Script compilation failed — Invalid process definition`,
the cause is always one of these three rules.

---

## Pre-lesson checklist

- [ ] `GETTING_STARTED.md` shared with students at least 24 hours before
- [ ] Codespace opened and confirmed working:
  ```bash
  nextflow run pipeline/main.nf -profile docker,test -stub
  ```
  Expected: 31 tasks complete (12 FASTP + 12 SALMON + 6 DESEQ2 + 1 MULTIQC)
- [ ] `results/multiqc/multiqc_report.html` opens correctly in the browser
- [ ] `course/docs/LESSON_COMMANDS.md` open on a second screen or tab
- [ ] Docker images confirmed present: `docker images | grep biocontainers`
- [ ] Samplesheet visible: `cat data/samplesheet.csv`

---

## Lesson structure

| Module | Topic | Duration |
|--------|-------|----------|
| A | Bioinformatics today — the Omics landscape in cancer | 15 min |
| B | What is Nextflow — building blocks and why it exists | 15 min |
| C | The biological story and reading the pipeline | 15 min |
| D | Channels — demo and walkthrough | 25 min |
| E | Processes — the Fastp walkthrough | 15 min |
| F | The biological payoff and homework | 5 min |

---

## Module A — Bioinformatics Today: The Omics Landscape in Cancer
**Duration: 15 minutes | Pure lecture, no code**

### Timing

| Time | Duration | Activity |
|------|----------|----------|
| 0:00 | 5 min | 📖 What is bioinformatics and why it matters now |
| 0:05 | 5 min | 🧬 The Omics landscape |
| 0:10 | 5 min | 🧬 Omics in cancer — why scale demands pipelines |

---

### 📖 What is bioinformatics and why it matters now (5 min)

Bioinformatics sits at the intersection of biology, computer science, and statistics.
It exists because modern biology produces more data than any human can interpret by hand.

The shift happened fast. In 2003, sequencing the first human genome took 13 years
and cost $3 billion. Today, a clinical whole-genome sequence costs under $500 and
takes 24 hours. A single sequencing run at a major centre produces terabytes per day.

The biological question — "which genes change in this tumor?" — is simple.
The computational path from raw data to answer involves dozens of tools, hundreds
of parameters, and thousands of intermediate files. Doing that reliably, at scale,
reproducibly: that is what bioinformatics is for. Nextflow is one of the main
answers the field has developed.

---

### 🧬 The Omics landscape (5 min)

**Speaker notes:**

"Omics" is the systematic, large-scale measurement of biological molecules.
Each layer asks a different question about the same cell:

| Layer | Measures | Key question |
|-------|----------|--------------|
| **Genomics** | DNA sequence | What mutations are present? |
| **Transcriptomics** | RNA expression | Which genes are active? |
| **Epigenomics** | DNA methylation | How is expression regulated? |
| **Proteomics** | Protein abundance | What is the cell actually doing? |
| **Multi-omics** | Two or more layers | How do the layers interact? |

A genomics pipeline takes FASTQ → VCF (mutations).
A transcriptomics pipeline — like ours today — takes FASTQ → count matrix → DE table.
Every pipeline faces the same structural challenge: many samples, many tools,
many steps, dependencies between steps, and a reproducibility requirement.
That is why Nextflow exists across all Omics fields.

*"Today we focus on transcriptomics — RNA-seq — the most widely used Omics
technique in cancer research."*

---

### 🧬 Omics in cancer (5 min)

**Speaker notes:**

Cancer is a disease of gene regulation as much as mutation. Even when DNA is intact,
a gene can be silenced — switched off. RNA-seq measures the transcriptome: the complete
set of messenger RNA molecules in a cell. By sequencing tumor and matched normal tissue
from the same patient and comparing them, we identify genes that are upregulated or
downregulated in cancer.

The Cancer Genome Atlas (TCGA) has generated RNA-seq data from over 11,000 tumors
across 33 cancer types. This scale creates an acute pipeline problem: one RNA-seq
sample generates 10–30 GB of raw data. Processing one sample takes 30–60 minutes.
Multiplied across thousands of patients — this demands automated, reproducible pipelines.

*"The dataset we work with today is six patients on chromosome 17.
The pipeline is structurally identical to what runs in clinical genomics today."*

**Reference:** TCGA Research Network, Nature Genetics 2013;
Stark et al., Nature Reviews Genetics 2019

---

## Module B — What is Nextflow: Building Blocks and Why It Exists
**Duration: 15 minutes | Pure lecture, no code**

### Timing

| Time | Duration | Activity |
|------|----------|----------|
| 0:15 | 5 min | 📖 The problem with shell scripts at scale |
| 0:20 | 5 min | 📖 The Nextflow solution — dataflow programming |
| 0:25 | 5 min | 📖 The three building blocks |

---

### 📖 The problem with shell scripts at scale (5 min)

The natural first instinct is to write a shell script: run Fastp, then Salmon,
then DESeq2. It works for one sample. Then you try to scale:

**Problem 1 — No parallelism.** A for loop over 12 samples runs them one at a time.

**Problem 2 — No resumability.** If the script fails at sample 10, you restart
from scratch — or write fragile checkpoint logic.

**Problem 3 — No reproducibility.** "Run this script" means nothing without knowing
which Salmon version was installed, which reference was used, which parameters were set.
Six months later on a different machine you will not get the same results.

**Problem 4 — No portability.** A script that works on your laptop needs significant
rewriting for a cluster, and rewriting again for cloud.

*"Nextflow solves all four. Here is how."*

---

### 📖 The Nextflow solution — dataflow programming (5 min)

Nextflow uses **dataflow programming**. Instead of telling the computer *when* to run
each step, you describe *what data each step needs* and *what it produces*.
Nextflow works out the execution order and parallelism automatically.

Data flows through **channels** — asynchronous queues. When data arrives in a channel,
the process consuming it fires automatically. 12 samples in a channel → 12 process
executions in parallel. You write the analysis once.

| Problem | Nextflow solution |
|---------|------------------|
| No parallelism | Automatic — processes fire when input arrives |
| No resumability | `-resume` — caches every task, reruns only what changed |
| No reproducibility | Every process declares its own Docker container |
| No portability | Executors — one config line to switch from laptop to SLURM to AWS |

**Reference:** Di Tommaso et al., Nature Biotechnology 2017

---

### 📖 The three building blocks (5 min)

A Nextflow pipeline is made of three kinds of object.
Understanding these three is enough to read any Nextflow pipeline.

**1. Processes** — the unit of work. Wraps one tool or script. Declares what it needs,
what it produces, and which Docker container to use. Runs in complete isolation —
its own directory, its own container, no shared state.

```
process FASTP {
    input:   FASTQ files for one sample
    output:  trimmed FASTQ + QC report
    script:  fastp --in1 ... --out1 ...
}
```

**2. Channels** — asynchronous queues carrying data between processes. Two types:
- **Queue channel** — emits each item once, consumed. Carries sample data.
- **Value channel** — emits the same item every time, never consumed. Carries
  shared resources like the Salmon index.

**3. Workflows** — the wiring. Connects processes through channels.

```
workflow {
    FASTP( ch_reads )
    SALMON( FASTP.out.reads, ch_index )
    DESEQ2( SALMON.out.counts )
}
```

Reading a workflow block tells you the entire pipeline at a glance.

```
Channels carry data ──► Processes transform it ──► Workflows wire it together
```

*"In a few minutes we will open the pipeline diagram. You now have the vocabulary
to read every box and every arrow in it."*

---

## Module C — The Biological Story and Reading the Pipeline
**Duration: 15 minutes**

### Timing

| Time | Duration | Type | Activity |
|------|----------|------|----------|
| 0:30 | 5 min | 🧬 | Biology snippet: RNA-seq and differential expression |
| 0:35 | 5 min | 📖 | Reading the pipeline |
| 0:40 | 5 min | 👁️ | Demo C: environment tour, stub run, preview results |

---

### 🧬 Biology snippet: RNA-seq and differential expression (5 min)

**Speaker notes:**

Every cell contains the same DNA. What makes a liver cell different from a neuron
is not which genes it has — it is which genes it expresses. RNA-seq measures
this expression. By sequencing tumor and matched normal tissue from the same patient
and comparing them, we find genes that have been silenced or overactivated in cancer.

**Our six patients:**

| Patients | Subtype | Key finding |
|----------|---------|-------------|
| patient1, patient2 | Breast (BRCA) | BRCA1 downregulated ~8× and ~5× in tumor |
| patient3, patient4 | Lung | TP53 downregulated ~7× and ~4× in tumor |
| patient5, patient6 | Colorectal | Both genes downregulated |

Data restricted to chromosome 17 — home to **BRCA1** (DNA repair; loss impairs
genome maintenance) and **TP53** (guardian of the genome; loss removes the cell's
primary apoptosis trigger).

Two patients per subtype rather than one: this is closer to how real studies work.
We can ask whether the expression changes are consistent across patients with the
same cancer type — a replication question.

*"That is why every patient appears twice in the samplesheet — tumor and normal.
DESeq2 needs both to run its comparison."*

**Reference:** Stark et al., Nature Reviews Genetics 2019;
Hollstein et al., Science 1991; Miki et al., Science 1994

---

### 📖 Reading the pipeline (5 min)

**Show the diagram from README.md and walk through it. For each step: tool name,
biological function, and file format flowing out.**

```
data/samplesheet.csv
      │  12 rows — 6 patients × tumor + normal
      ▼
  [ Fastp ]
      │  Trims adapters, removes low-quality bases
      │  FASTQ → cleaned FASTQ + JSON QC report
      ▼
  [ Salmon ]
      │  Maps reads to chr17 transcripts, estimates counts per transcript
      │  No BAM produced — faster and lighter than traditional alignment
      │  cleaned FASTQ → quant.sf (count table, one per sample)
      │
      └──────────────────────────┐
                                 ▼
                           [ DESeq2 / PyDESeq2 ]
                                 │  Groups tumor + normal by patient
                                 │  Fits a negative binomial model
                                 │  Tests: is expression different tumor vs normal?
                                 │  quant.sf pair → results TSV + volcano plot
                                 ▼
                           [ MultiQC ]
                                 Collects Fastp JSON + Salmon logs
                                 → single HTML QC report
```

**What to emphasise:**

- Every box is a **process**. Every arrow is a **channel**. This is the vocabulary from Module B.
- File format changes at each step: FASTQ → quant.sf → TSV. Each format is the expected input of the next tool.
- Salmon produces no BAM file. This is why it runs in under 30 seconds per sample
  rather than several minutes.
- DESeq2 fires **6 times** (once per patient), not 12. It needs tumor and normal together.
  The `groupTuple` operator handles the pairing — we will see this in the diff_expr subworkflow.
- DESeq2 uses **PyDESeq2** — a Python reimplementation of the R DESeq2 statistical model.
  Same negative binomial model, same results, ~400 MB container vs ~2.1 GB for R/Bioconductor.
- MultiQC fires **once** after `.collect()` gathers all QC files. This is the `.collect()` operator.
- `pipeline/` contains the portable Nextflow pipeline. `course/` contains the teaching material.
  Point this out — students can take `pipeline/` and run it on their own data independently.

---

### 👁️ Demo C: Environment tour, stub run, preview results (5 min)

```bash
# Show the repository layout
tree -L 2

# Show the samplesheet
cat data/samplesheet.csv
```

*"12 rows. 6 patients. Tumor and normal for each. The `condition` column
tells DESeq2 which sample to compare against which. This CSV is the
only input the pipeline needs."*

```bash
# Run stub mode
nextflow run pipeline/main.nf -profile docker,test -stub
```

While it runs: *"Stub mode fires every process but creates empty files instantly
instead of running the real tools. Count the tasks: 12 Fastp + 12 Salmon +
6 DESeq2 + 1 MultiQC = 31 total. DESeq2 fires 6 times — once per patient —
because `groupTuple` paired the 12 Salmon outputs into 6 patient groups first."*

```bash
# Show the work/ directory
ls work/
ls work/<ab>/<hash>/
cat work/<ab>/<hash>/.command.sh
```

*"Every task has its own directory in work/. `.command.sh` shows the exact command
that ran. `.command.err` shows any errors. When your pipeline breaks —
and it will — these two files answer every question."*

```bash
# Preview results — do not open yet
ls results/deseq2/
ls results/multiqc/
```

*"These are pre-computed results from running the full pipeline on our six patients.
We will open them at the end of the lesson — after the channels and processes
make sense."*

---

## Module D — Channels: Demo and Walkthrough
**Duration: 25 minutes**

### Timing

| Time | Duration | Type | Activity |
|------|----------|------|----------|
| 0:45 | 8 min | 📖 | Channels in depth — queue vs value, operators |
| 0:53 | 7 min | 👁️ | Demo D: run module_d_channels.nf, narrate output |
| 1:00 | 10 min | 📖 | Walkthrough D: module_d_samplesheet.nf |

---

### 📖 Channels in depth (8 min)

**Queue channels** — emit each item once. When a process consumes an item, it is gone.
12 items in a channel → process fires 12 times, automatically, in parallel.

```nextflow
// created from a CSV file
channel.fromPath('data/samplesheet.csv').splitCsv(header: true)
```

**Value channels** — emit the same item every time. Never consumed. Use for shared
resources that every task needs: the Salmon index, a reference genome, a config file.

```nextflow
// the Salmon index — shared by all 12 Salmon tasks
ch_index = channel.value(file(params.salmon_index))
```

If the Salmon index were in a queue channel, the first task would consume it and
the remaining 11 tasks would hang waiting for a value that never arrives.

**Key operators for this pipeline:**

| Operator | What it does |
|----------|-------------|
| `.map {}` | Transform each item — CSV row → `[meta, r1, r2]` tuple |
| `.filter {}` | Keep items matching a condition |
| `.branch {}` | Split one channel into multiple named channels |
| `.groupTuple()` | Group items sharing a key — pairs tumor + normal for DESeq2 |
| `.collect()` | Gather all items into one list — all QC files for MultiQC |
| `.view {}` | Print each item for debugging — does not consume items |

**The `meta` map convention:**

```nextflow
def meta = [
    id        : row.sample,     // "patient1_tumor"
    patient   : row.patient,    // "patient1"  — grouping key for DESeq2
    condition : row.condition,  // "tumor" or "normal"
    subtype   : row.subtype     // "BRCA", "lung", "colorectal"
]
[ meta, file(row.fastq_1), file(row.fastq_2) ]
```

`meta` travels with files through every process. Without it, you lose track of
which results belong to which patient the moment files enter the first process.

**Nextflow 26 note:** Channel factories use lowercase `channel` not `Channel`.
This changed in Nextflow 26. All course files use the correct lowercase form.

---

### 👁️ Demo D: Channel demo (7 min)

```bash
nextflow run course/demos/module_d_channels.nf
```

**Narrate the output in four parts:**

**Part 1 — value channel:**
*"The value channel emits 'reference/salmon_index' every time it is read.
Same item, never consumed. That is how all 12 Salmon tasks share the same index."*

**Part 2 — raw CSV rows:**
*"Each row arrives as a Groovy Map object — `row.sample`, `row.condition`, etc.
Useful for reading, but a process expects files and typed values, not a raw Map.
That is what `.map {}` fixes."*

**Part 3 — after .map to tuple:**
*"12 items. Each is a three-element tuple: a metadata Map plus two file paths.
Notice that `meta.patient` is the grouping key — `patient1`, `patient2`, etc.
When this channel reaches `groupTuple`, items with the same patient ID
are grouped together. That is how DESeq2 gets tumor and normal simultaneously."*

**Part 4 — .filter:**
*"`.filter` keeps only items where the condition returns true. Six tumor samples
instead of twelve. This is how you would restrict to a specific subtype or
skip failed-QC samples."*

---

### 📖 Walkthrough D: Loading the samplesheet (10 min)

Open `course/walkthroughs/module_d_samplesheet.nf` in the editor.
Read through the three annotated steps with learners. Then run it.

```bash
nextflow run course/walkthroughs/module_d_samplesheet.nf
```

**After Step 1 — splitCsv:**
*"What does this channel emit? 12 Map objects — one per row.
A Map is NOT directly usable as a process input. Step 2 fixes this."*

**After Step 2 — .map:**
*"Same 12 items, different shape. Each is now a three-element tuple.
Why does the number not change? Because `.map` transforms — it does not
filter or split. Every input produces exactly one output."*

**On `file()`:**
*"Why `file()` and not just the string from `row.fastq_1`?
`file()` creates a Nextflow Path object. When the process runs, Nextflow
stages this file — creates a symlink — in the task work directory before
the script runs. Without `file()`, the process gets a string but the file
is never staged. The tool fails with 'no such file'.
This is the single most common mistake in Nextflow."*

**After Step 3 — .view:**
*"`.view {}` prints each item without consuming it. The channel still
emits all 12 items downstream. Add `.view {}` anywhere when debugging.
Remove it before production."*

---

## Module E — Processes: The Fastp Walkthrough
**Duration: 15 minutes**

### Timing

| Time | Duration | Type | Activity |
|------|----------|------|----------|
| 1:10 | 5 min | 🧬 | Biology snippet: adapters and read quality |
| 1:15 | 10 min | 📖 | Walkthrough E: module_e_fastp.nf |

---

### 🧬 Biology snippet: Adapters and read quality (5 min)

**Speaker notes:**

When a DNA library is prepared, short synthetic sequences called **adapters** are
attached to both ends of each fragment. The sequencer uses these to grip the fragment.
If the fragment is shorter than the read length, the sequencer reads through into the
adapter on the far side — producing adapter contamination at the 3' end of the read.

Additionally, sequencing quality degrades toward the end of each read. The last 20–30
bases are statistically less reliable than the first 50. Low-quality bases introduce
errors that look like mutations — false positives in downstream analysis.

**Fastp handles both:**
- Detects and removes adapter sequences automatically (no adapter file needed)
- Trims bases below quality threshold (Phred < 20 = 1% error rate)
- Removes reads that become too short after trimming (< 36 bp)
- Produces a JSON report with statistics (used by MultiQC)

*"That is why Fastp is the first step in our pipeline — it ensures every read that
reaches Salmon is clean, uncontaminated, and long enough to align reliably."*

**Reference:** Chen et al., Bioinformatics 2018

---

### 📖 Walkthrough E: The Fastp process (10 min)

Open `course/walkthroughs/module_e_fastp.nf` in the editor. Walk through each
section of the process with learners. Then run it.

**On `tag`:**
*"The tag is what you see in the Nextflow log. Without it: 'FASTP (1)'.
With it: 'FASTP (patient1_tumor)'. When 12 tasks run, you need to know which is which.
Note the closure `{ }` — required in Nextflow 26 when the tag references input variables."*

**On `container`:**
*"This process runs inside this Docker image — a frozen snapshot of Fastp 0.23.4
with all its dependencies. Every process can use a different container. You never
install Fastp yourself. If you move from your laptop to AWS tomorrow, the same
container runs there. That is reproducibility."*

**On `publishDir`:**
*"When the task finishes, copy outputs to this directory. The work/ directory is
Nextflow's internal space — publishDir is where YOU find results. The closure `{ }` is
again required in Nextflow 26 because it references `meta.id`."*

**On `input`:**
*"This declares the SHAPE of what the process expects. It must match what the channel
delivers: a tuple of [meta, path, path]. If the shapes don't match: error."*

**On `output` and `emit`:**
*"Each output line declares what the process creates. The `emit:` label gives it a name.
In the workflow, `FASTP.out.reads` gets the trimmed FASTQs. `FASTP.out.json` gets the
QC report. These are separate channels — they flow to different places."*

**On `script`:**
*"The `script:` label is required in Nextflow 26. Everything between the triple quotes
is a shell script that runs INSIDE the container. Variables like `${meta.id}` are
resolved by Nextflow before the script runs — they become literal strings."*

**On `stub`:**
*"The stub is what runs with `-stub`. It creates the expected output files but empty.
This lets you test pipeline structure without waiting for real tools."*

Run it:
```bash
nextflow run course/walkthroughs/module_e_fastp.nf -stub
```

*"12 tasks fired. One per sample. All from a single process definition.
That is what channels do — they drive parallelism."*

Show the work directory:
```bash
ls work/<hash>/<hash>/
cat work/<hash>/<hash>/.command.sh
```

*"`.command.sh` is the actual shell script. `.command.run` is how Nextflow launched it.
`.command.err` is stderr. These three files debug everything."*

---

## Module F — The Biological Payoff and Homework
**Duration: 5 minutes**

### Timing

| Time | Duration | Type | Activity |
|------|----------|------|----------|
| 1:25 | 3 min | 👁️ | Demo F: open DESeq2 results and MultiQC |
| 1:28 | 2 min | 🏠 | Introduce homework exercise |

---

### 👁️ Demo F: The results (3 min)

Open the pre-computed results. These were generated by running the full pipeline
on the chr17 dataset.

```bash
# Show DESeq2 output for patient1
cat results/deseq2/patient1/patient1_de_results.tsv | head -20
```

*"Each row is a gene. `log2FoldChange` tells you how much expression changed
between tumor and normal. A negative value means the gene is less expressed in tumor —
it has been silenced. Look at BRCA1: log2FC of approximately -3, meaning about
8-fold downregulation in this breast cancer patient's tumor."*

```bash
# Open MultiQC report
# (In Codespaces: Simple Browser or port forward)
```

*"MultiQC collected all 12 Fastp reports and all 12 Salmon mapping reports.
In one HTML page you can see whether any sample failed QC or had unusually
low mapping rate. This is how you catch problems before they reach DESeq2."*

---

### 🏠 Homework: Filter by subtype (2 min)

**Introduce:**

*"The homework is a single exercise. Open `course/homework/homework_filter_subtype.nf`.
It is a simplified copy of the full pipeline. Your job: add one line of code — a
`.filter` — to make it process only breast cancer patients instead of all six."*

*"The hints are in the file. The expected result: 11 tasks instead of 31.
The syntax is exactly what we saw in the channel demo, Part 4."*

*"The solution is in `course/homework/solution_filter_subtype.nf` — but try it
yourself first."*

---

## Post-lesson notes

### What students leave with

1. **Vocabulary:** process, channel (queue vs value), workflow, operator, meta map
2. **Mental model:** channels carry data → processes transform it → workflows wire it
3. **Practical skill:** can read a pipeline diagram and trace data flow
4. **Debugging instinct:** work directory, `.command.sh`, `.command.err`
5. **Biological context:** RNA-seq, differential expression, tumor vs normal comparison

### Connecting to the full course

This 90-minute lesson covers Modules A–C and partial Module D of the 6-hour course.
Students ready for more can continue with:

- **Operators in depth** — groupTuple, branch, collect
- **Writing their own process** — adding a gene filter step
- **Configuration** — profiles, executors, resource tuning
- **nf-core** — connecting to the community and nf-core/rnaseq
- **Seqera Platform** — monitoring, launching, collaboration

### Timing buffer

The lesson is designed for exactly 90 minutes with no buffer. If you run short:
- Extend Demo C (show more work/ directory contents)
- Show the DAG report (`results/pipeline_info/dag.html`)
- Discuss groupTuple in more detail using the main.nf code

If you run long:
- Cut Demo F to 1 minute (just show the TSV, skip MultiQC)
- Cut the homework introduction to 1 minute (just point them at the file)
- In Module D, skip the `.filter` narration — students will discover it in homework

---

## Bibliography

1. Di Tommaso P, et al. Nextflow enables reproducible computational workflows.
   *Nature Biotechnology* 35, 316–319 (2017).

2. Stark R, Grzelak M, Hadfield J. RNA sequencing: the teenage years.
   *Nature Reviews Genetics* 20, 631–656 (2019).

3. The Cancer Genome Atlas Research Network. The Cancer Genome Atlas Pan-Cancer
   analysis project. *Nature Genetics* 45, 1113–1120 (2013).

4. Hollstein M, et al. p53 mutations in human cancers.
   *Science* 253, 49–53 (1991).

5. Miki Y, et al. A strong candidate for the breast and ovarian cancer
   susceptibility gene BRCA1. *Science* 266, 66–71 (1994).

6. Chen S, et al. fastp: an ultra-fast all-in-one FASTQ preprocessor.
   *Bioinformatics* 34, i884–i890 (2018).

7. Patro R, et al. Salmon provides fast and bias-aware quantification of
   transcript expression. *Nature Methods* 14, 417–419 (2017).

8. Love MI, Huber W, Anders S. Moderated estimation of fold change and
   dispersion for RNA-seq data with DESeq2.
   *Genome Biology* 15, 550 (2014).

9. Ewels P, et al. MultiQC: summarize analysis results for multiple tools
   and samples in a single report. *Bioinformatics* 32, 3047–3048 (2016).

10. Muzellec B, et al. PyDESeq2: a python package for bulk RNA-seq differential
    expression analysis. *Bioinformatics* 39, btad547 (2023).