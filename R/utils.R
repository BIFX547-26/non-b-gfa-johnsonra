# Utility functions shared across motif finders.

# Default parameter values matching the original gfa CLI defaults.
.gfa_defaults <- list(
  # G-Quadruplex
  minGQrep      = 3L,
  maxGQspacer   = 7L,
  # Mirror Repeat
  minMRrep      = 10L,
  maxMRspacer   = 100L,
  # Inverted Repeat
  minIRrep      = 6L,
  maxIRspacer   = 100L,
  shortIRcut    = 9L,
  shortIRspacer = 4L,
  # Direct Repeat
  minDRrep      = 10L,
  maxDRrep      = 300L,
  maxDRspacer   = 100L,
  # A-Phased Repeat
  minATracts    = 3L,
  minATractSep  = 10L,
  maxATractSep  = 11L,
  maxAPRlen     = 9L,
  minAPRlen     = 3L,
  # Z-DNA
  minZlen       = 10L,
  # Short Tandem Repeat
  minSTR        = 1L,
  maxSTR        = 9L,
  minSTRbp      = 8L,
  # Subset classification thresholds
  minCruciformRep       = 6L,
  maxCruciformSpacer    = 4L,
  minTriplexYRpercent   = 10L,
  maxTriplexSpacer      = 8L,
  maxSlippedSpacer      = 0L
)

#' Read a FASTA file into a named character vector
#'
#' @param path Path to a FASTA file (single or multi-sequence).
#' @return A named character vector where names are sequence identifiers and
#'   values are the DNA sequences (upper-case).
#' @export
read_fasta <- function(path) {
  # TODO: implement
  stop("read_fasta() not yet implemented")
}

# Internal: convert a REP list returned from C into a data.frame.
.rep_to_df <- function(rep_list, seq_name) {
  # TODO: implement after C interface is in place
  stop(".rep_to_df() not yet implemented")
}

#' Convert a nonbgfa data.frame to a GRanges object
#'
#' Requires the \pkg{GenomicRanges} package (Bioconductor).
#'
#' @param df A `data.frame` returned by one of the `find_*()` functions.
#' @return A [GenomicRanges::GRanges] object.
#' @export
to_granges <- function(df) {
  rlang::check_installed("GenomicRanges",
                         reason = "to convert results to GRanges format")
  rlang::check_installed("IRanges",
                         reason = "to convert results to GRanges format")
  GenomicRanges::GRanges(
    seqnames = df$seq_name,
    ranges   = IRanges::IRanges(start = df$start, end = df$end),
    strand   = df$strand,
    df[, setdiff(names(df), c("seq_name", "start", "end", "strand"))]
  )
}
