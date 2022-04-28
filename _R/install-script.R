all_pkg <- readr::read_csv("_data/packages.csv")

cran_pkg <- all_pkg |> 
  dplyr::filter(repo == "CRAN") |> 
  dplyr::pull(package)

gh_pkg <- all_pkg |> 
  dplyr::filter(repo == "GitHub") |> 
  dplyr::pull(package)

cran_pkg |>
  install.packages(repos = "https://cran.rstudio.com/" )
