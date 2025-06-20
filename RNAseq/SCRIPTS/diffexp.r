# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} 

in_counts = args[1]

if (length(args)==1) {
    # default output file
    out_pref = ""
} else {
    # user can specify a prefix to prepend to the output file names
    out_pref = args[2]
}

# Check and install BiocManager if necessary
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# Check and install DESeq2 if necessary
if (!requireNamespace("DESeq2", quietly = TRUE)) {
  BiocManager::install("DESeq2")
}

# Load DESeq2 package
library("DESeq2")

# load raw counts create by merging Salmon output
raw_counts = read.csv(args[1], stringsAsFactors=F, sep="\t", row.names=1)
raw_counts = round(raw_counts, 0)

# get experiment design info from column names
info = data.frame(strsplit(names(raw_counts), "_"))
names(info) = names(raw_counts)
info = data.frame(t(info))
names(info) = c("timepoint", "replicate")

# from DESeq2 quick start guide
dds <- DESeqDataSetFromMatrix(countData = raw_counts, colData = info, design = ~ timepoint + replicate)
dds <- DESeq(dds)

combs = combn(unique(info$timepoint),2) ## 2x3 table with each pair of combinations

apply(combs, 2, function(pair) { ## from chatGPT
  write.table(
    results(dds, contrast = c("timepoint", pair[1], pair[2])), 
    file = paste0(out_pref,"deseq2_out_", pair[1], "_vs_", pair[2], ".csv"),
    sep = "\t", quote = FALSE
      )})


hits=c()
comparisons=c()

apply(combs, 2, function(pair) { 
    res = results(dds, contrast = c("timepoint", pair[1], pair[2])),
    res = na.omit(res),
    hits = append(hits, length(res[res$padj<0.05 & (res$log2FoldChange < -2 | res$log2FoldChange > 2),1])), ## get number of transcripts with significant p-val and at least 2x fold change
    comparisons = append(comparisons, paste0(pair[1],"_vs_",pair[2]))
    })

repcombs = combn(unique(info$replicate),2)

apply(repcombs, 2, function(pair) { 
    res = results(dds, contrast = c("replicate", pair[1], pair[2])),
    res = na.omit(res),
    hits = append(hits, length(res[res$padj<0.05 & (res$log2FoldChange < -2 | res$log2FoldChange > 2),1])), ## get number of transcripts with significant p-val and at least 2x fold change
    comparisons = append(comparisons, paste0(pair[1],"_vs_",pair[2]))
    })

names(hits) = comparisons
write.table(hits, paste0(out_pref, "deseq2_out_signif_hits.csv"), sep = "\t", quote = FALSE)


