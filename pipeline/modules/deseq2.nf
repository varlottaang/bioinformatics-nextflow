/*
 * DESEQ2 — Differential expression analysis (per patient)
 *
 * Biology: Compares transcript counts between tumor and normal tissue from
 *          the same patient. Uses a negative binomial model to determine
 *          which genes are significantly up- or down-regulated in the tumor.
 *          Uses PyDESeq2 — a Python implementation of the DESeq2 statistical model.
 *
 * Input:  [group_meta, [meta_tumor, meta_normal], [quant_tumor, quant_normal]]
 *         tx2gene — transcript-to-gene mapping file (value channel)
 * Output: [group_meta, results_tsv] — differential expression results
 *         [group_meta, volcano_png] — volcano plot visualization
 */

process DESEQ2 {

    tag { "${group_meta.id}" }

    container 'quay.io/biocontainers/pydeseq2:0.4.11--pyhdfd78af_0'

    publishDir { "${params.outdir}/deseq2/${group_meta.id}" }, mode: 'copy'

    input:
    tuple val(group_meta), val(metas), path(quant_dirs)
    path(tx2gene)

    output:
    tuple val(group_meta), path("${group_meta.id}_de_results.tsv"), emit: results
    tuple val(group_meta), path("${group_meta.id}_volcano.png"), emit: plots

    script:
    """
    #!/usr/bin/env python3
    import pandas as pd
    import numpy as np
    from pydeseq2.dds import DeseqDataSet
    from pydeseq2.ds import DeseqStats
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    # Load transcript-to-gene mapping
    tx2gene = pd.read_csv('${tx2gene}', sep='\\t', names=['tx_id', 'gene_id', 'gene_name'])

    # Load quant.sf files and aggregate to gene level
    sample_info = []
    counts_dict = {}

    quant_dirs = '${quant_dirs}'.split()
    meta_ids = '${metas.collect { it.id }.join(" ")}'.split()
    meta_conditions = '${metas.collect { it.condition }.join(" ")}'.split()

    for sample_id, condition, qdir in zip(meta_ids, meta_conditions, quant_dirs):
        quant_file = f"{qdir}/quant.sf"
        df = pd.read_csv(quant_file, sep='\\t')
        # Map transcripts to genes and sum
        df = df.merge(tx2gene[['tx_id', 'gene_name']], left_on='Name', right_on='tx_id')
        gene_counts = df.groupby('gene_name')['NumReads'].sum()
        counts_dict[sample_id] = gene_counts
        sample_info.append({'sample': sample_id, 'condition': condition})

    # Build count matrix
    counts_df = pd.DataFrame(counts_dict).fillna(0).astype(int)
    clinical_df = pd.DataFrame(sample_info).set_index('sample')

    # Run DESeq2
    dds = DeseqDataSet(counts=counts_df.T, clinical=clinical_df, design="~condition")
    dds.deseq2()

    # Statistical testing
    stat_res = DeseqStats(dds, contrast=['condition', 'tumor', 'normal'])
    stat_res.summary()
    results = stat_res.results_df

    # Save results
    results.to_csv('${group_meta.id}_de_results.tsv', sep='\\t')

    # Volcano plot
    fig, ax = plt.subplots(figsize=(8, 6))
    sig = results[(results['padj'] < 0.05) & (results['log2FoldChange'].abs() > 1)]
    nonsig = results.drop(sig.index)

    ax.scatter(nonsig['log2FoldChange'], -np.log10(nonsig['pvalue']),
               alpha=0.3, s=10, c='gray', label='Not significant')
    ax.scatter(sig['log2FoldChange'], -np.log10(sig['pvalue']),
               alpha=0.7, s=20, c='red', label='Significant (padj<0.05, |LFC|>1)')

    ax.set_xlabel('log2 Fold Change (tumor vs normal)')
    ax.set_ylabel('-log10(p-value)')
    ax.set_title('${group_meta.id} — Differential Expression')
    ax.legend()
    ax.axhline(-np.log10(0.05), ls='--', c='black', alpha=0.3)
    ax.axvline(-1, ls='--', c='black', alpha=0.3)
    ax.axvline(1, ls='--', c='black', alpha=0.3)
    plt.tight_layout()
    plt.savefig('${group_meta.id}_volcano.png', dpi=150)
    """

    stub:
    """
    echo -e "gene\\tlog2FoldChange\\tpvalue\\tpadj" > ${group_meta.id}_de_results.tsv
    echo -e "BRCA1\\t-3.2\\t0.001\\t0.01" >> ${group_meta.id}_de_results.tsv
    touch ${group_meta.id}_volcano.png
    """
}
