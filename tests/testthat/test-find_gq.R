test_that("find_gq() errors until C interface is implemented", {
  skip("Phase 2 C interface not yet implemented")
  result <- find_gq(example_fasta)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), nrow(expected$GQ))
  expect_equal(result$start, expected$GQ$Start)
  expect_equal(result$end,   expected$GQ$Stop)
})
