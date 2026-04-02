#' Find mirror repeats (triplex DNA)
#'
#' Searches a DNA sequence for mirror repeats — identical sequences facing
#' each other on the same strand — which can form intramolecular triplex
#' (H-DNA) structures.
#'
#' @param seq A single DNA sequence as a character string, or a path to a
#'   FASTA file.
#' @param minMRrep Minimum length of each repeat arm. Default: `10`.
#' @param maxMRspacer Maximum spacer length between arms. Default: `100`.
#' @param minTriplexYRpercent Minimum purine/pyrimidine content (%) for the
#'   triplex subset flag. Default: `10`.
#' @param maxTriplexSpacer Maximum spacer for triplex subset flag. Default: `8`.
#' @param format Output format: `"data.frame"` (default) or `"GRanges"`.
#' @return A `data.frame` (or `GRanges`) with columns: `seq_name`, `start`,
#'   `end`, `strand`, `length`, `spacer`, `num_repeats`, `remainder`,
#'   `subset`.
#' @seealso [find_nonb()]
#' @references Cer et al. (2013) \doi{10.1093/nar/gks955}
#' @export
find_mr <- function(seq,
                    minMRrep              = 10L,
                    maxMRspacer           = 100L,
                    minTriplexYRpercent   = 10L,
                    maxTriplexSpacer      = 8L,
                    format                = c("data.frame", "GRanges")) {
  format <- match.arg(format)
  # TODO: call .Call("gfa_find_mr", ...)
  stop("find_mr() not yet implemented: C interface pending Phase 2")
}
