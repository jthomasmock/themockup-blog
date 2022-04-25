library(crosstalk)

cars <- MASS::Cars93[1:20, c("Manufacturer", "Model", "Type", "Price")]
data <- SharedData$new(cars)

bscols(
        widths = c(3, 9),
        list(
                filter_checkbox("type", "Type", data, ~Type),
                filter_slider("price", "Price", data, ~Price, width = "100%"),
                filter_select("mfr", "Manufacturer", data, ~Manufacturer)
        ),
        reactable(data, minRows = 10)
)
