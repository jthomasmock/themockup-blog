rmarkdown::render(
  input = "static/gt-cookbook.Rmd",
  envir = new.env()
  )

rmarkdown::render(
  input = "static/gt-cookbook-advanced.Rmd",
  envir = new.env()
)
