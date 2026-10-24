# Pins the current output: exact bytes of scripts/leafcutter_ds.R's two output
# files for the small inputs in pinned/. The expected files were written by
# running these same commands once on leafcutter commit 2c9907e (R 4.3.3,
# rstan 2.21.8, reference BLAS on Linux). They record that build's optimizer
# results to the last printed digit, so a change of platform, BLAS, compiler or
# Stan version can change them without anything being wrong; the properties of
# the same runs are tested in test_leafcutter_ds.R.
#   Rscript scripts/tests/test_leafcutter_ds_pinned.R
this_file <- sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE))
if (length(this_file) != 1) stop("run this file with Rscript")
here <- dirname(normalizePath(this_file, mustWork=TRUE))
script <- file.path(dirname(here), "leafcutter_ds.R")
pinned <- file.path(here, "pinned")
rscript <- file.path(R.home("bin"), "Rscript")

root <- tempfile("leafcutter_ds_pinned")
dir.create(root)

file_bytes <- function(path) readBin(path, "raw", file.info(path)$size)

check_pinned <- function(name, args) {
  prefix=file.path(root, name)
  status=system2(rscript, c(shQuote(script), "-o", shQuote(prefix), args),
                 stdout=file.path(root, paste0(name, ".out")), stderr=file.path(root, paste0(name, ".err")))
  stopifnot(status == 0)
  for (suffix in c("_cluster_significance.txt", "_effect_sizes.txt")) {
    got=file_bytes(paste0(prefix, suffix))
    expected=file_bytes(file.path(pinned, paste0(name, suffix)))
    if (!identical(got, expected)) {
      cat("expected", file.path(pinned, paste0(name, suffix)), ":\n")
      cat(readLines(file.path(pinned, paste0(name, suffix))), sep="\n")
      cat("got:\n")
      cat(readLines(paste0(prefix, suffix)), sep="\n")
      stop(name, suffix, " differs from the pinned output")
    }
  }
}

test_pinned_default_with_exons <- function() {
  check_pinned("default_exons", c("-p", "2", "-e", shQuote(file.path(pinned, "exons.txt")),
                                  shQuote(file.path(pinned, "counts.txt")), shQuote(file.path(pinned, "groups.txt"))))
}

test_pinned_confounders_random_init <- function() {
  check_pinned("confounders_random", c("-p", "2", "-i", "4", "-c", "10", "--init", "random", "--seed", "3",
                                       shQuote(file.path(pinned, "counts.txt")), shQuote(file.path(pinned, "groups_confounders.txt"))))
}

tests=list(test_pinned_default_with_exons=test_pinned_default_with_exons,
           test_pinned_confounders_random_init=test_pinned_confounders_random_init)
for (name in names(tests)) {
  cat(name, "\n")
  tests[[name]]()
}
unlink(root, recursive=TRUE)
