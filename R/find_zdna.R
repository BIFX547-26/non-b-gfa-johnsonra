#' Find Z-DNA motifs
#'
#' Searches a DNA sequence for Z-DNA motifs — alternating purine/pyrimidine
#' runs that can adopt a left-handed double helix conformation. Results
#' include the Klysik-Vasquez (KV) thermodynamic score.
#'
#' @param seq A single DNA sequence as a character string, or a path to a
#'   FASTA file.
#' @param minZlen Minimum length of the alternating purine/pyrimidine run.
#'   Default: `10`.
#' @param format Output format: `"data.frame"` (default) or `"GRanges"`.
#' @return A `data.frame` (or `GRanges`) with columns: `seq_name`, `start`,
#'   `end`, `strand`, `length`, `spacer` (KV score), `num_repeats`,
#'   `remainder`, `subset`.
#' @seealso [find_nonb()]
#' @references Cer et al. (2013) \doi{10.1093/nar/gks955}
#' @export
find_zdna <- function(seq,
                      minZlen = 10L,
                      format  = c("data.frame", "GRanges")) {
  format <- match.arg(format)
  # TODO: call .Call("gfa_find_zdna", ...)
  stop("find_zdna() not yet implemented: C interface pending Phase 2")
}
