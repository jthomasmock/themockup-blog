


X = x*cos(θ) - y*sin(θ)
Y = x*sin(θ) + y*cos(θ)

float tempX = x - cx;
float tempY = y - cy;

// now apply rotation
float rotatedX = tempX*cos(theta) - tempY*sin(theta);
float rotatedY = tempX*sin(theta) + tempY*cos(theta);

// translate back
x = rotatedX + cx;
y = rotatedY + cy;


rotate_point <- function(pt, o, a){
  
  angle = a * (pi/180) # convert to radians
  rotated_x <- cos(angle) * (pt[1] - o[1]) - sin(angle) * (pt[2] - 0[2]) + o[1]
  rotated_y <- sin(angle) * (pt[1] - o[1]) - sin(angle) * (pt[2] - 0[2]) + o[1]
  
  c(rotated_x, rotated_y)
}

rotate_point(c(1, 1), c(0.5, 0.5), 130)



square(size = 1, angle = 125) 
%>% 
  ggplot()+#size 2 and rotate 45 degrees
  geom_polygon(aes(x=x, y=y), fill=NA, color='black')+
  geom_polygon(aes(x=x2, y=y2), fill=NA, color='red')+
  coord_fixed()

n<-24*12
df.list<-list()
for (j in 1:24){ #iterate through the rows
  for (i in 1:12){ #iterate through the columns
    displace<-runif(1,-j,j) #a random number is generated from a uniform distribution with min=-j and max=j
    rotate<-runif(1,-j,j) #random number to rotate the square
    temp<-square(x=i+displace, y=j+displace, angle=rotate) #create a square at column i and row j displaced by displace
    df.list[[n]]<-temp #save the data frame with the square n on a list
    n<-n-1
  }
}
df.list[[2]] %>% 
  ggplot()+#size 2 and rotate 45 degrees
  # geom_polygon(aes(x=x, y=y), fill=NA, color='black')+
  geom_polygon(aes(x=x2, y=y2), fill=NA, color='red')+
  coord_fixed()

ggplot() + 
  lapply(df.list[1:5], function(square_data) {
    geom_polygon(data = square_data, aes(x = x2, y = y2), fill=NA, color='black')}
  )+
  coord_fixed()+
  theme_void()

crossing(rows = 1:24, columns = 1:12) %>% 
  pmap()

library(tidyverse)

schotter_plot <- function(
  n_rows = 24,
  n_cols = 12,
  control_distance = 40,
  control_rotation = 100,
  square_fill = NA,
  square_color = "black",
  square_alpha = 0.2
) {
  create_square <- function(x0 = 1, y0 = 1, size = 1, angle = 0) {
    xor <- x0 + size / 2 # X origin (center of the square)
    yor <- y0 + size / 2 # Y origin (center of the square)

    tibble(
      xor = xor,
      yor = yor,
      x = c(x0, x0 + size, x0 + size, x0),
      y = c(y0, y0, y0 + size, y0 + size)
    ) %>% mutate(
      # For rotation
      x2 = (x - xor) * cos(angle) - (y - yor) * sin(angle) + xor,
      # for rotation  
      y2 = (x - xor) * sin(angle) + (y - yor) * cos(angle) + yor
    )
  }
  
  max_rows <- n_rows

  alter_square <- function(rows, columns, ctrl_distance = control_distance, ctrl_rotation = control_rotation, max_val = max_rows) {
    displacement <- runif(1, -rows / ctrl_distance, rows / ctrl_distance)
    rotation <- runif(1, -rows / ctrl_rotation, rows / ctrl_rotation)
    
    square_out <- create_square(x = columns + displacement, y = rows + displacement, angle = rotation) %>% 
      mutate(sq_fill = scales::col_numeric(c("#3686d3", "lightblue", "white"), domain = c(1, max_val))(rows))
    
    square_out 
  }

  df_squares <<- crossing(rows = 1:n_rows, columns = 1:n_cols) %>%
    pmap_dfr(alter_square, .id = "grp")
  
  ggplot(data = df_squares) +
  geom_polygon(
        aes(x = x2, y = y2, fill = sq_fill, group = grp),
        alpha = square_alpha,
        color = square_color
      ) +
    # theme_background(color = back_color)+
    # theme_void() +
    coord_fixed() +
    scale_fill_identity() +
    scale_y_reverse()

}

# Source: https://atespin.netlify.app/post/schotter/schotter/

library(ggtext)

test_plot <- schotter_plot(n_rows = 24, n_cols = 20, control_distance = 50, control_rotation = 100, square_color =  "grey3", square_alpha = 0.9)
final_plot <- test_plot +
  # geom_richtext(aes(x = 11, y = 2.5), 
  #               label = "The MockUp Blog", 
  #               size= 14.5, 
  #               family = "Chivo",
  #               color = "white",
  #               alpha = 0.8,
  #               hjust = 0.5,
  #               fill = NA, label.color = NA, # remove background and outline
  #               label.padding = grid::unit(rep(0, 4), "pt") # remove padding
  # ) +
  theme_void()

ggsave("logo-plot.png", dpi = "retina")
alter_square(30, 10) %>% 
  ggplot()+#size 2 and rotate 45 degrees
  geom_polygon(aes(x=x, y=y), fill=NA, color='black')+
  geom_polygon(aes(x=x2, y=y2, fill = sq_fill), color='red')+
  scale_fill_identity() +
  coord_fixed()


row_max <- 30
scales::col_numeric(c("#3686d3", "#88398a"), domain = c(1, row_max))(21) %>% scales::show_col()
