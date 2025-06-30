#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is at least three arguments: if not, return an error
if (length(args)<3) {
  stop("At least three arguments must be supplied (input file).n", call.=FALSE)
} 
out_pref = args[1]
files = args[2:]

print(paste0("Running analysis for ", length(files), " files, using output prefix: ",out_pref))

# Check and install BiocManager if necessary
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# Check and install BioConductor packages if necessary
if (!requireNamespace("DESeq2", quietly = TRUE)) {
  BiocManager::install("DESeq2")
}
if (!requireNamespace("tximport", quietly = TRUE)) {
  BiocManager::install("tximport")
}
if (!requireNamespace("biomaRt", quietly = TRUE)) {
  BiocManager::install("biomaRt")
}
if (!requireNamespace("TxDb.Hsapiens.UCSC.hg38.knownGene", quietly = TRUE)) {
  BiocManager::install("TxDb.Hsapiens.UCSC.hg38.knownGene")
}

# Load packages
library("DESeq2")
library("tximport")
library("biomaRt")
library("TxDb.Hsapiens.UCSC.hg38.knownGene")

# out_pref = "names_test_" ## for testing

# files = c("D0_1_quant.csv", "D0_2_quant.csv", "D0_3_quant.csv", "D1_1_quant.csv", "D1_2_quant.csv", "D1_3_quant.csv", "D5_1_quant.csv", "D5_2_quant.csv", "D5_3_quant.csv") # locally
# files = c("DATA/CSV/EXPDIR/D0_1/quant.sf", "DATA/CSV/EXPDIR/D0_2/quant.sf", "DATA/CSV/EXPDIR/D0_3/quant.sf", "DATA/CSV/EXPDIR/D1_1/quant.sf", "DATA/CSV/EXPDIR/D1_2/quant.sf", "DATA/CSV/EXPDIR/D1_3/quant.sf", "DATA/CSV/EXPDIR/D5_1/quant.sf", "DATA/CSV/EXPDIR/D5_2/quant.sf", "DATA/CSV/EXPDIR/D5_3/quant.sf") # thru smk

info = data.frame( lapply(files, function(path){
  splitpath = unlist(strsplit(path, "/"))
  return(strsplit(splitpath[length(splitpath)-1], "_"))
}))

info = data.frame(t(info))
names(info) = c("timepoint", "replicate")


template = read.csv(files[1], sep="\t")
txdb = TxDb.Hsapiens.UCSC.hg38.knownGene
k = keys(txdb, keytype="TXNAME")
k = k[k %in% template$Name]
tx2gene = select(txdb, k, "GENEID", "TXNAME")
tx2gene = na.omit(tx2gene)

ensembl = useMart("ensembl", dataset = "hsapiens_gene_ensembl")
mapping = getBM(attributes=c('entrezgene_id', 'ensembl_gene_id', 'hgnc_symbol'), mart = ensembl, filters='entrezgene_id', values=tx2gene$GENEID)
mapping = mapping[!duplicated(mapping$entrezgene_id), ]
rownames(mapping) = mapping$entrezgene_id
mapping = mapping[c("ensembl_gene_id", "hgnc_symbol")]

full_mapping = data.frame(row.names=unique(tx2gene$GENEID))
full_mapping$ensembl_gene_id = rep("x")
full_mapping$hgnc_symbol = rep("x")
full_mapping[rownames(mapping),]$ensembl_gene_id = mapping$ensembl_gene_id
full_mapping[rownames(mapping),]$hgnc_symbol = mapping$hgnc_symbol
full_mapping[is.na(full_mapping)] = "x"
full_mapping[full_mapping == ""] = "x"

txi = tximport(files, type="salmon", tx2gene=tx2gene, countsFromAbundance = "no")

txi_tpm = data.frame(txi$abundance)
colnames(txi_tpm) = files
txi_tpm$ensembl_gene_id = full_mapping[rownames(txi_tpm),]$ensembl_gene_id;
txi_tpm$hgnc_symbol = full_mapping[rownames(txi_tpm),]$hgnc_symbol;
txi_tpm$entrezgene_id = rownames(txi_tpm)
meta_cols = c("entrezgene_id", "ensembl_gene_id", "hgnc_symbol")
data_cols = setdiff(colnames(txi_tpm), meta_cols)
txi_tpm = txi_tpm[, c(meta_cols, data_cols)]
write.table(
  txi_tpm, 
  file = paste0(out_pref,"txi_tpms_gene.csv"),
  sep = "\t", quote = FALSE, row.names=FALSE
    )

txi_raw = data.frame(txi$counts)
colnames(txi_raw) = files
txi_raw$ensembl_gene_id = full_mapping[rownames(txi_raw),]$ensembl_gene_id;
txi_raw$hgnc_symbol = full_mapping[rownames(txi_raw),]$hgnc_symbol;
txi_raw$entrezgene_id = rownames(txi_raw)
meta_cols = c("entrezgene_id", "ensembl_gene_id", "hgnc_symbol")
data_cols = setdiff(colnames(txi_raw), meta_cols)
txi_raw = txi_raw[, c(meta_cols, data_cols)]
write.table(
  txi_raw, 
  file = paste0(out_pref,"txi_raws_gene.csv"),
  sep = "\t", quote = FALSE, row.names=FALSE
    )


ddsTxi = DESeqDataSetFromTximport(txi, colData = info, design = ~ timepoint + replicate)
ddsTxi = DESeq(ddsTxi)

combs = combn(unique(info$timepoint),2) ## 2x3 table with each pair of combinations

apply(combs, 2, function(pair) { 
  res = results(ddsTxi, contrast = c("timepoint", pair[1], pair[2]));
  res$ensembl_gene_id = full_mapping[rownames(res),]$ensembl_gene_id;
  res$hgnc_symbol = full_mapping[rownames(res),]$hgnc_symbol;
  res$entrezgene_id = rownames(res)
  res = res[, c(9,7,8,1,2,3,4,5,6)]
  write.table(
    res, 
    file = paste0(out_pref,"deseq2_out_", pair[1], "_vs_", pair[2], ".csv"),
    sep = "\t", quote = FALSE, row.names=FALSE
      )})

timepoints_hits = apply(combs, 2, function(pair) { 
  res = results(ddsTxi, contrast = c("timepoint", pair[1], pair[2]))
  res = na.omit(res)
  
  sig_hits = sum(res$padj < 0.05 & abs(res$log2FoldChange) > 2)
  comp_name = paste0(pair[1], "_vs_", pair[2])
  
  return(c(comparison = comp_name, hits = sig_hits))
})

repcombs = combn(unique(info$replicate),2)

apply(repcombs, 2, function(pair) { 
  res = results(ddsTxi, contrast = c("replicate", pair[1], pair[2]));
  res$ensembl_gene_id = full_mapping[rownames(res),]$ensembl_gene_id;
  res$hgnc_symbol = full_mapping[rownames(res),]$hgnc_symbol;
  res$entrezgene_id = rownames(res)
  res = res[, c(9,7,8,1,2,3,4,5,6)]
  write.table(
    res, 
    file = paste0(out_pref,"deseq2_out_replicates_", pair[1], "_vs_", pair[2], ".csv"),
    sep = "\t", quote = FALSE, row.names=FALSE
      )})

replicates_hits = apply(repcombs, 2, function(pair) { 
  res = results(ddsTxi, contrast = c("replicate", pair[1], pair[2]))
  res = na.omit(res)
  
  sig_hits = sum(res$padj < 0.05 & abs(res$log2FoldChange) > 2)
  comp_name = paste0(pair[1], "_vs_", pair[2])
  
  return(c(comparison = comp_name, hits = sig_hits))
})

write.table(timepoints_hits, paste0(out_pref, "deseq2_out_signif_hits.csv"), col.names=FALSE, sep = "\t", quote = FALSE)
write.table(replicates_hits, paste0(out_pref, "deseq2_out_signif_hits.csv"), col.names=FALSE, sep = "\t", quote = FALSE, append=TRUE)





