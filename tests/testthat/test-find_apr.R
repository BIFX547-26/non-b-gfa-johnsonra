test_that("find_apr() errors until C interface is implemented", {
  skip("Phase 2 C interface not yet implemented")
  result <- find_apr(example_fasta)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), nrow(expected$APR))
  expect_equal(result$start, expected$APR$Start)
  expect_equal(result$end,   expected$APR$Stop)
})
