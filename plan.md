# Plan: Refactor GFA C Code into `nonbgfa` R Package

## Problem Statement
The `gfa` tool is a C command-line program that finds non-B DNA-forming motifs in genomic
sequences. The goal is to convert it into a proper R package (`nonbgfa`) where the C
motif-finding algorithms are callable directly from R via `.Call()`, returning `data.frame`
or `GenomicRanges` objects.

## Approach
- **Integration method**: `.Call()` interface — refactor C functions to accept R objects
  (SEXP) and return R lists/data frames, eliminating the global state and file I/O
- **Package name**: `nonbgfa`
- **Return types**: `data.frame` by default; `GenomicRanges` if `format = "GRanges"`
  (optional Bioconductor dependency checked at runtime, not at install time)

---

## Target Package Structure

```
nonbgfa/
├── DESCRIPTION
├── NAMESPACE
├── README.md                          # Updated for R package
├── R/
│   ├── find_nonb.R                    # Unified wrapper: all (or selected) motif finders
│   ├── find_ir.R                      # Inverted repeats
│   ├── find_mr.R                      # Mirror repeats
│   ├── find_dr.R                      # Direct repeats
│   ├── find_gq.R                      # G-quadruplexes
│   ├── find_zdna.R                    # Z-DNA
│   ├── find_str.R                     # Short tandem repeats
│   ├── find_apr.R                     # A-phased repeats
│   └── utils.R                        # read_fasta(), to_granges(), shared defaults
├── src/
│   ├── Makevars                       # Unix build flags (-O2 -lm)
│   ├── Makevars.win                   # Windows build flags
│   ├── R_interface.c                  # NEW: .Call() entry points (one per motif type)
│   ├── init.c                         # NEW: R_registerRoutines() + R_useDynamicSymbols()
│   ├── gfa.h                          # MODIFIED: remove global array declarations
│   ├── cdna.c / rcdna.c               # MODIFIED: accept dna[] as parameter, not global
│   ├── findIR.c                       # MODIFIED: signature takes/returns local structs
│   ├── findMR.c                       # (same pattern as findIR.c)
│   ├── findDR.c
│   ├── findGQ.c
│   ├── findZDNA.c
│   ├── findSTR.c
│   ├── findAPR.c
│   ├── process_repeats.c
│   ├── is_subset.c
│   ├── nulls.c
│   └── read_fasta.c / read_mult_fasta.c
├── inst/
│   ├── extdata/
│   │   └── example.fasta              # Extracted from test_files.tar
│   └── legacy/
│       ├── gfa_main.c                 # Original main() preserved here
│       └── Makefile                   # Original Makefile preserved here
├── tests/
│   └── testthat/
│       ├── helper-data.R              # Load expected outputs from inst/extdata/
│       ├── test-find_ir.R
│       ├── test-find_mr.R
│       ├── test-find_dr.R
│       ├── test-find_gq.R
│       ├── test-find_zdna.R
│       ├── test-find_str.R
│       ├── test-find_apr.R
│       └── test-find_nonb.R
├── vignettes/
│   └── introduction.qmd
└── .github/
    └── workflows/
        └── R-CMD-check.yml
```

---

## C Refactoring Strategy

### Key Changes

1. **Remove global arrays** — `dna[]`, `dna2[]`, `dna3[]`, `irep[]`, `mrep[]`, `drep[]`,
   `grep[]`, `zrep[]`, `srep[]`, `arep[]`, `gisle[]`, `rcgisle[]`, `pAPRs[]` are currently
   declared as static globals (up to 300 MB for DNA, 2.5M entries for REP arrays). After
   refactoring these become heap-allocated locals inside each `.Call()` entry point and are
   `free()`'d before returning to R.

2. **Remove `main()`** — Moved to `inst/legacy/gfa_main.c` for reference; the shared library
   entry point becomes `R_init_nonbgfa()` in `init.c`.

3. **Remove file I/O from print functions** — `print_gff_file.c` and `print_tsv_file.c`
   become unused; the R interface converts REP[] arrays directly to R named lists.

4. **Refactor function signatures** — Every `findXX()` function gains explicit `char *dna`,
   `char *dna2`, `char *dna3`, and `REP *` array parameters instead of referencing externs.

5. **`R_interface.c`** — One `.Call()`-registered function per motif type:
   ```c
   SEXP gfa_find_ir(SEXP r_seq, SEXP r_minIRrep, SEXP r_maxIRspacer, ...);
   SEXP gfa_find_mr(SEXP r_seq, SEXP r_minMRrep, SEXP r_maxMRspacer, ...);
   SEXP gfa_find_dr(SEXP r_seq, SEXP r_minDRrep, SEXP r_maxDRrep, SEXP r_maxDRspacer, ...);
   SEXP gfa_find_gq(SEXP r_seq, SEXP r_minGQrep, SEXP r_maxGQspacer, ...);
   SEXP gfa_find_zdna(SEXP r_seq, SEXP r_minZlen, ...);
   SEXP gfa_find_str(SEXP r_seq, SEXP r_minSTR, SEXP r_maxSTR, SEXP r_minSTRbp, ...);
   SEXP gfa_find_apr(SEXP r_seq, SEXP r_minATracts, ...);
   ```
   Each function: unpacks SEXP args → allocates local arrays → calls refactored motif finder
   → converts REP[] to R named list → frees memory → returns SEXP.

6. **`init.c`** — Registers all `.Call()` routines with `R_registerRoutines()` and calls
   `R_useDynamicSymbols(FALSE)` for safe namespace lookup.

### REP[] → R Named List / data.frame Column Mapping

| C field     | R column name  | Notes                                     |
|-------------|----------------|-------------------------------------------|
| `start`     | `start`        | 1-based, consistent with R/Bioconductor   |
| `end`       | `end`          | 1-based                                   |
| `strand`    | `strand`       | `0` → `"+"`, `1` → `"-"`                 |
| `len`       | `length`       | Length of repeat unit / G-run size        |
| `loop`      | `spacer`       | Spacer size (or KV score for Z-DNA)       |
| `num`       | `num_repeats`  | Times pattern repeated / permutations     |
| `sub`       | `remainder`    | DR remainder / min loop / island count    |
| `special`   | `subset`       | `TRUE` if cruciform / triplex / slipped   |

---

## Work Phases & Todos

### Phase 1: Package Scaffolding
| ID | Task |
|----|------|
| `scaffold-pkg` | Create DESCRIPTION, NAMESPACE, R/, src/, tests/, inst/, .github/ skeletons |
| `extract-testdata` | Extract test_files.tar → inst/extdata/; keep expected TSV output for tests |

### Phase 2: C Code Refactoring
| ID | Task |
|----|------|
| `c-remove-globals` | Remove extern globals from gfa.h; update all C files to use local/passed-in arrays |
| `c-remove-main` | Move main() + CLI arg parsing to inst/legacy/; update Makefile reference |
| `c-refactor-finders` | Update findIR/MR/DR/GQ/ZDNA/STR/APR to take explicit array params |
| `c-r-interface` | Write R_interface.c with one SEXP entry point per motif type |
| `c-init` | Write init.c with R_registerRoutines and R_useDynamicSymbols(FALSE) |
| `c-makevars` | Write src/Makevars (Unix) and src/Makevars.win with -O2 -lm |

### Phase 3: R Interface Layer
| ID | Task |
|----|------|
| `r-utils` | Write utils.R: read_fasta(), .rep_to_df(), to_granges(), shared defaults |
| `r-find-each` | Write find_ir.R, find_mr.R, find_dr.R, find_gq.R, find_zdna.R, find_str.R, find_apr.R with roxygen2 docs |
| `r-find-nonb` | Write find_nonb.R: unified function, returns named list of data.frames |

### Phase 4: Documentation & Vignette
| ID | Task |
|----|------|
| `docs-roxygen` | Run devtools::document() and review all man/ pages |
| `docs-vignette` | Write vignettes/introduction.qmd with worked example on inst/extdata/example.fasta |
| `docs-readme` | Update README.md: R package install instructions, quick-start, citation |

### Phase 5: Tests
| ID | Task |
|----|------|
| `tests-scaffold` | Set up testthat infrastructure (usethis::use_testthat()) |
| `tests-helper` | Write helper-data.R to load expected TSV outputs from inst/extdata/ |
| `tests-each` | Write one test file per motif type comparing results to expected TSV output |
| `tests-nonb` | Write test-find_nonb.R testing the unified function end-to-end |

### Phase 6: CI/CD
| ID | Task |
|----|------|
| `ci-gha` | Write .github/workflows/R-CMD-check.yml (ubuntu, macos, windows × R-release + R-devel) |

### Dependency Order

```
scaffold-pkg
├── extract-testdata
├── c-remove-globals
│   └── c-refactor-finders
│       ├── c-r-interface ──── c-init
│       └── (also needs c-remove-main)
├── c-remove-main
├── c-makevars
├── r-utils
│   └── r-find-each (also needs c-init)
│       └── r-find-nonb
│           └── docs-roxygen
│               ├── docs-vignette
│               └── docs-readme
└── tests-scaffold
    └── tests-helper (also needs extract-testdata)
        ├── tests-each (also needs r-find-each)
        └── tests-nonb (also needs r-find-nonb)
            └── ci-gha
```

---

## Notes & Considerations

- **Memory management**: The original code uses fixed static globals sized at worst-case
  maximums (300M chars for DNA, 2.5M entries per REP array). In the `.Call()` refactor, all
  allocations become explicit heap allocations that must be `free()`'d before returning to R.
  The strategy per array type is:

  1. **`dna` (forward strand)** — R already owns this string. Use `CHAR(STRING_ELT(r_seq, 0))`
     to get a `const char*` pointer directly into R's memory and `strlen()` for the length.
     Zero new allocation needed.

  2. **`dna2` (reverse complement) and `dna3` (complement)** — Allocate at exactly
     `seq_len + 1` bytes each. Only allocate for motif types that require them (IR and GQ
     need both; Z-DNA and STR need neither).

  3. **REP result arrays** — Allocate upfront using the sequence length and the relevant
     minimum motif size parameter as a divisor, with a small floor:
     ```c
     int cap = (seq_len / min_unit > 1024) ? seq_len / min_unit : 1024;
     REP *irep = malloc(cap * sizeof(REP));
     ```
     Safe caps by motif type:

     | Motif | Worst-case density | Cap formula |
     |-------|--------------------|-------------|
     | Z-DNA (min 10 bp) | 1 per 10 bp | `seq_len / 10` |
     | STR   (min 8 bp total) | 1 per 8 bp | `seq_len / 8` |
     | IR    (min 6 bp stem) | 1 per 12 bp | `seq_len / 12` |
     | GQ    (min 3G × 4 runs) | 1 per 12 bp | `seq_len / 12` |
     | MR / DR (min 10 bp stem) | 1 per 20 bp | `seq_len / 20` |
     | APR   (min 3 A-tracts) | 1 per 30 bp | `seq_len / 30` |

     Alternatively, use `realloc()`-based growth (start at 1024, double on overflow) if a
     single upfront cap is undesirable.

  4. **`G_Island` arrays (`gisle`, `rcgisle`)** — At most one G-island per `minGQrep` bases.
     Allocate `(seq_len / minGQrep + 1) * sizeof(G_Island)`.

  5. **`pAPRs`** — At most one A-tract per `minAPRlen` bases.
     Allocate `(seq_len / minAPRlen + 1) * sizeof(potential_Bent_DNA)`.

  This eliminates the 300 MB + 2.5M-entry static footprint entirely for typical inputs while
  remaining safe even for whole-chromosome sequences.

- **Vignette format**: Using Quarto (`.qmd`) instead of R Markdown (`.Rmd`). Requires the
  `quarto` R package in `Suggests` in DESCRIPTION, Quarto CLI installed on the build system,
  and a `quarto-dev/quarto-actions/setup` step in the GitHub Actions workflow.

- **GenomicRanges**: Use `rlang::check_installed("GenomicRanges")` at runtime inside
  `to_granges()` rather than listing GenomicRanges in `Imports`, so the package does not
  require Bioconductor to install.

- **Windows build**: `-lm` is implicit on MSVC but required for GCC/MinGW on Windows; omit
  it from `Makevars.win` or guard with a compiler check.

- **Strand encoding**: The C code uses `0`/`1` for strand; convert to `"+"`/`"-"` in the
  R interface layer for Bioconductor compatibility.

- **1-based positions**: GFA already uses 1-based positions — consistent with R/Bioconductor
  conventions; no coordinate conversion needed.

- **Legacy preservation**: Keep the original `main()` and `Makefile` in `inst/legacy/` so
  the original command-line tool can still be compiled independently if needed.

- **print_gff_file.c / print_tsv_file.c**: These become dead code after the refactor. Keep
  them in `inst/legacy/` alongside `gfa_main.c` rather than deleting, in case they are
  useful for debugging or re-enabling CLI output in the future.
