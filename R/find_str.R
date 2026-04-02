#' Find short tandem repeats (STR)
#'
#' Searches a DNA sequence for short tandem repeats — repeating elements of
#' 1–9 bp occurring three or more times in tandem (microsatellites).
#'
#' @param seq A single DNA sequence as a character string, or a path to a
#'   FASTA file.
#' @param minSTR Minimum length of the repeating unit (bp). Default: `1`.
#' @param maxSTR Maximum length of the repeating unit (bp). Default: `9`.
#' @param minSTRbp Minimum total length of the STR locus (bp). Default: `8`.
#' @param format Output format: `"data.frame"` (default) or `"GRanges"`.
#' @return A `data.frame` (or `GRanges`) with columns: `seq_name`, `start`,
#'   `end`, `strand`, `length`, `spacer`, `num_repeats`, `remainder`,
#'   `subset`.
#' @seealso [find_nonb()]
#' @references Cer et al. (2013) \doi{10.1093/nar/gks955}
#' @export
find_str <- function(seq,
                     minSTR   = 1L,
                     maxSTR   = 9L,
                     minSTRbp = 8L,
                     format   = c("data.frame", "GRanges")) {
  format <- match.arg(format)
  # TODO: call .Call("gfa_find_str", ...)
  stop("find_str() not yet implemented: C interface pending Phase 2")
}
