---
title: "Easily parsing JSON in R with jsonlite and purrr"
description: |
  It's turtles all the way down...
author:
  - name: Thomas Mock
base_url: https://themockup.blog
date: 05-22-2020
output: 
  distill::distill_article:
    toc: true
    toc_depth: 3
categories:
  - NFL
  - tidyverse
  - JSON
  - web scraping
  - API
  - purrr
preview: distill-preview.png
twitter:
  site: "@thomas_mock"
  creator: "@thomas_mock"
---



![It's turtles all the way down, source: https://en.wikipedia.org/wiki/Turtles_all_the_way_down](distill-preview.jpg)

# Don't bury the lede

While many R programmers are comfortable with lists, vectors, dataframes, tibbles - `JSON` has long been a source of pain and/or fear for many.

Because this is going to be a bit of a journey, I don't want to bury the lede. I've got the final code below, which is just a few lines, and a major helper package for examining nested lists such as JSON. Most of this post is about some approaches to exploring `JSON` outputs and deeply nested lists. Additionally the `tidyverse` team even has an article on various approaches to "rectangling" nested data/`JSON` [here](https://tidyr.tidyverse.org/articles/rectangle.html).

We're using another NFL example this week, namely we are collecting data from ESPN's Quarterback Rating (QBR) API endpoint. The output website that this API feeds is available [here](https://www.espn.com/nfl/qbr/_/season/2019/seasontype/2) and the API endpoint itself is available [here](https://site.web.api.espn.com/apis/fitt/v3/sports/football/nfl/qbr?region=us&lang=en&qbrType=seasons&seasontype=2&isqualified=true&sort=schedAdjQBR%3Adesc&season=2019).

## RStudio Viewer

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">The RStudio viewer is also super useful for navigating, once you have the data in R</p>&mdash; Hadley Wickham (@hadleywickham) <a href="https://twitter.com/hadleywickham/status/1264907162884726785?ref_src=twsrc%5Etfw">May 25, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Additionally, the RStudio IDE itself has a lovely way of parsing through `JSON` files, including the ability to output the code to access specific parts of `JSON` objects!

First - open the `raw_json` with the RStudio viewer.

<div class="layout-chunk" data-layout="l-body">

```r
View(raw_json)
```

</div>


![You get a list-viewer type experience with RStudio itself, and it still has search!](rstudio-json.png)

Once it is open you can search for specific object names or navigate similarly to `listviewer`.

![We can see our same `athlete` object as a dataframe!](rstudio-json-opened.png)

Once you search and find something of interest (for example `athletes` object), you can click on the scroll to open it as a temp object in the viewer, or just click the table-arrow button to copy the code to access this level of the object to the console.

![The scroll = temp open and named as the code to access this level of the object eg `raw_json[["athletes"]]`](open-json.png)

Lastly, once you click the scroll you can see the actual underling `athletes` object, which is our dataframe of interest! The highlighted name is the code used to access that object.

![The opened `athletes` object opened through the RStudio Viewer](opened-json.png)


## `listviewer`

Secondly, the `listviewer` package is also fantastic! It lets you explore `JSON` interactively in a similar way to the RStudio Viewer. We can use this to interactively explore the data before we start coding away.

Because we're looking at the 2019 season, I know that Lamar Jackson is the top QB in the dataset, and we can guess at some of the other columns by going to the actual [webpage this API is building](https://www.espn.com/nfl/qbr/_/season/2019/seasontype/2). From that we can assume there are columns for player name, team name, QBR, PAA, PLAYS, etc.

![Example of the website](website_ss.png)

I'll let you do this interactively because that's how'd you use in RStudio, and try searching for:  
- Lamar Jackson -- important for finding the QB names  
- 81.8 -- this one is important as a data point  

In the interactive `jsonedit()` viewer below:  

<div class="layout-chunk" data-layout="l-body">

```r
# interactive list or JSON viewer
# note that you can change the view to raw JSON or the more 
# interactive `View` option
listviewer::jsonedit(raw_json, height = "800px", mode = "view")
```

preservec4b84836b8b3a32e

</div>


Now as you're searching notice that it provides the depth/level you're in. The only awkward part is like JavaScript it indexes from 0... so as usual note that `index == 0` is `index == 1` in R. The `listviewer` author does have a little helper function in this [regard](http://timelyportfolio.github.io/listviewer/reference/number_unnamed.html).

For example:

If you search for `81.8` and click on the `81.8` cell, you'll get the following location:

`object > athletes > categories > 0 > totals > 0 > 0`  

which is equivalent to the following in R:  

`raw_json[["athletes"]][["categories"]][[1]][["totals"]][[1]][[1]]` 

The `listviewer` strategy can allow you to explore interactively, while the code below is more of moving through the `JSON` object in R. 

Let's get into the code itself to extract and work with the `JSON` data.

## The code

This utilizes `purrr` to get at the various components, but I'll also show how to do this with mostly base R.

<div class="layout-chunk" data-layout="l-body">

```r
library(tidyverse)
library(jsonlite)

# link to the API output as a JSON file
url_json <- "https://site.web.api.espn.com/apis/fitt/v3/sports/football/nfl/qbr?region=us&lang=en&qbrType=seasons&seasontype=2&isqualified=true&sort=schedAdjQBR%3Adesc&season=2019"

# get the raw json into R
raw_json <- jsonlite::fromJSON(url_json)

# get names of the QBR categories
category_names <- pluck(raw_json, "categories", "labels", 1)

# Get the QBR stats by each player (row_n = player)
get_qbr_data <- function(row_n) {
  purrr::pluck(raw_json, "athletes", "categories", row_n, "totals", 1) %>% 
    as.double() %>% 
    set_names(nm = category_names)
}

# create the dataframe and tidy it up
ex_output <- pluck(raw_json, "athletes", "athlete") %>%
  as_tibble() %>%
  select(displayName, teamName:teamShortName, headshot) %>%
  mutate(data = map(row_number(), get_qbr_data)) %>% 
  unnest_wider(data) %>% 
  mutate(headshot = pluck(headshot, "href"))

glimpse(ex_output)
```

```
Rows: 30
Columns: 14
$ displayName   <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Bre…
$ teamName      <chr> "Ravens", "Chiefs", "Saints", "Cowboys", "Sea…
$ teamShortName <chr> "BAL", "KC", "NO", "DAL", "SEA", "DET", "HOU"…
$ headshot      <chr> "https://a.espncdn.com/i/headshots/nfl/player…
$ TQBR          <dbl> 81.8, 76.3, 71.7, 70.2, 69.8, 69.6, 68.7, 66.…
$ PA            <dbl> 63.1, 52.4, 31.3, 44.1, 39.1, 24.9, 38.5, 26.…
$ QBP           <dbl> 613, 585, 419, 690, 674, 353, 662, 620, 374, …
$ TOT           <dbl> 103.7, 97.3, 62.6, 93.1, 90.9, 56.1, 91.6, 70…
$ PAS           <dbl> 55.0, 71.6, 53.1, 70.7, 58.3, 44.5, 52.0, 47.…
$ RUN           <dbl> 39.1, 14.3, 1.6, 10.0, 10.6, 1.6, 19.8, 6.3, …
$ EXP           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ PEN           <dbl> 2.2, 5.0, 1.9, 2.6, 1.5, 1.9, 1.4, 3.7, 2.3, …
$ QBR           <dbl> 81.1, 78.0, 74.2, 71.2, 69.4, 73.1, 69.5, 64.…
$ SAC           <dbl> -7.4, -6.5, -6.0, -9.7, -20.6, -8.0, -18.5, -…
```

</div>



Now that you have explored the raw data via `jsonedit` and you see where we are going with this, we can actually try playing around with it in R.

# [It's Turtles all the way down](https://en.wikipedia.org/wiki/Turtles_all_the_way_down)

At it's heart `JSON` is essentially nested lists of lists of strings, vectors, or other objects - it's really just lists full of other objects all the way down.

While there are many reasons WHY `JSON` is actually a great format for things like... surprise JavaScript! It isn't the easiest to work with in R for interactive coding as the trusty old dataframe/tibble.

My goal today is to show you a few techniques from `tidyr` that can make quick work of most cleanly structured `JSON`, although there are weird examples out in the wild of `JSON` formats that are not as straightforward.

# Raw Data and Libraries

Today we need the `tidyverse` and [`jsonlite`](https://github.com/jeroen/jsonlite/) packages. We can read in the `JSON` via `jsonlite::fromJSON()` on the raw url string. Huge shoutout to ROpenSci, Jeroen Oooms, Duncan Temple Lang, and Lloyd Hilaiel for this package! A basic vignette can be found [here](https://cran.r-project.org/web/packages/jsonlite/vignettes/json-aaquickstart.html).

First off note that I'm using `fromJSON()` which has `simplifyVector = TRUE` - this means some lists will automatically get converted to data.frames, matrices, etc. I'll be using `fromJSON()` for my example today.

After reviewing this post, Hadley Wickham mentioned that he often prefers `jsonlite::read_json()` as it doesn't do this conversion and leaves everything as a list.  His approach is at the end of this blogpost. 

<div class="layout-chunk" data-layout="l-body">

```r
library(tidyverse)
library(jsonlite)

url_json <- "https://site.web.api.espn.com/apis/fitt/v3/sports/football/nfl/qbr?region=us&lang=en&qbrType=seasons&seasontype=2&isqualified=true&sort=schedAdjQBR%3Adesc&season=2019"

raw_json <- jsonlite::fromJSON(url_json)
```

</div>


# Viewing JSON

I highly recommend that you DON'T blindy call `str()` on `JSON` objects - you'll get several pages of `stuff` output to your console.

<aside> Feel free to try it, as an example exercise, but you've been warned. 👀 </aside>

I will almost always default to starting with a tool like `listviewer::jsonedit()` that you get a feel for what the structure looks like. Alternatively, you can use of the examples below to work your way through `JSON` files more programatically in just R.

Per my friend [Josiah Parry](https://twitter.com/JosiahParry/status/1262369767236796417?s=20), `str()` has a `max.level` argument - this is very helpful for `JSON` as it lets you slowly expand the depth of what you're looking at!

## Level 1

<div class="layout-chunk" data-layout="l-body">

```r
str(raw_json, max.level = 1)
```

```
List of 7
 $ pagination     :List of 6
 $ athletes       :'data.frame':	30 obs. of  2 variables:
 $ currentSeason  :List of 5
 $ requestedSeason:List of 5
 $ glossary       :'data.frame':	10 obs. of  2 variables:
 $ categories     :'data.frame':	1 obs. of  6 variables:
 $ currentValues  :List of 13
```

</div>


We can see that the `JSON` file at depth 1 has info about the pages returned, athletes in our dataset, what season it is, glossary of terms, categories, and current values.

However some of those lists are actually reporting as lists of lists and lists of dataframes, so let's try one level deeper.

## Level 2

Now we can see that pagination is just character strings of length 1 after two levels, however athletes has: two objects, a dataframe called `athlete` with 30 rows, and a list called `categories` is a list of length 30 (which aligns with the length of the athlete dataframe).

This is probably the most interesting data to us, as we're looking for about 30-32 QBs from this API endpoint. Now, how do we actually get at these list objects?

<div class="layout-chunk" data-layout="l-body">

```r
str(raw_json, max.level = 2)
```

```
List of 7
 $ pagination     :List of 6
  ..$ count: int 30
  ..$ limit: int 50
  ..$ page : int 1
  ..$ pages: int 1
  ..$ first: chr "http://site.api.espn.com:80/apis/fitt/v3/sports/football/nfl/qbr?isqualified=true&lang=en&qbrtype=seasons&regio"| __truncated__
  ..$ last : chr "http://site.api.espn.com:80/apis/fitt/v3/sports/football/nfl/qbr?isqualified=true&lang=en&qbrtype=seasons&regio"| __truncated__
 $ athletes       :'data.frame':	30 obs. of  2 variables:
  ..$ athlete   :'data.frame':	30 obs. of  20 variables:
  ..$ categories:List of 30
 $ currentSeason  :List of 5
  ..$ year       : int 2019
  ..$ displayName: chr "2019"
  ..$ startDate  : chr "2019-07-31T07:00:00.000+0000"
  ..$ endDate    : chr "2020-02-06T07:59:00.000+0000"
  ..$ type       :List of 6
 $ requestedSeason:List of 5
  ..$ year       : int 2019
  ..$ displayName: chr "2019"
  ..$ startDate  : chr "2019-07-31T07:00:00.000+0000"
  ..$ endDate    : chr "2020-02-06T07:59:00.000+0000"
  ..$ type       :List of 6
 $ glossary       :'data.frame':	10 obs. of  2 variables:
  ..$ abbreviation: chr [1:10] "EXP" "PA" "PAS" "PEN" ...
  ..$ displayName : chr [1:10] "EXP SACK" "Points Added" "Pass" "PENALTY" ...
 $ categories     :'data.frame':	1 obs. of  6 variables:
  ..$ name        : chr "general"
  ..$ displayName : chr "General "
  ..$ labels      :List of 1
  ..$ names       :List of 1
  ..$ displayNames:List of 1
  ..$ descriptions:List of 1
 $ currentValues  :List of 13
  ..$ qbrType    : chr "seasons"
  ..$ sport      : chr "football"
  ..$ league     : chr "nfl"
  ..$ season     : int 2019
  ..$ seasontype : int 2
  ..$ week       : NULL
  ..$ conference : int 9
  ..$ isQualified: logi TRUE
  ..$ limit      : int 50
  ..$ page       : int 1
  ..$ lang       : chr "en"
  ..$ sort       :List of 2
  ..$ region     : chr "us"
```

</div>


## Get at the list

Because the `JSON` file is parsed into R as nested lists, we can access various parts of it through base R with either the `$` or with `[[` + name. Full details around subsetting lists and vectors are available in [Advanced R](https://adv-r.hadley.nz/subsetting.html).

Let's try these out by trying to access:  
- `raw_json` to `athletes`  (`raw_json[["athletes"]]`)
- Looking at it's structure, again using the `max.level` argument to prevent extra printing.

I'd like to note that I'll be switching back and forth a bit between `$` and `[[` subsetting, as both accomplish the same thing, where `$` is faster to type, but `[[` is a bit more strict. Also to access by numerical position, you HAVE to use `[[`.

<aside> 
Again, full details around subsetting lists and vectors are available in [Advanced R](https://adv-r.hadley.nz/subsetting.html). This is definitely worth reading for edge cases, pitfalls, and lots of nice examples that go beyond the scope of this blog post.
</aside>


<div class="layout-chunk" data-layout="l-body">

```r
raw_json$athletes %>% str(max.level = 1)
```

```
'data.frame':	30 obs. of  2 variables:
 $ athlete   :'data.frame':	30 obs. of  20 variables:
 $ categories:List of 30
```

```r
# this does the same thing!
raw_json[["athletes"]] %>% str(max.level = 1)
```

```
'data.frame':	30 obs. of  2 variables:
 $ athlete   :'data.frame':	30 obs. of  20 variables:
 $ categories:List of 30
```

</div>


### Access the dataframe

We can get to the dataframe itself by going one list deeper and we now see a traditional output of `str()` when called on a dataframe!

<div class="layout-chunk" data-layout="l-body">

```r
# json -> list --> dataframe 
raw_json$athletes$athlete %>% str(max.level = 1)
```

```
'data.frame':	30 obs. of  20 variables:
 $ id           : chr  "3916387" "3139477" "2580" "2577417" ...
 $ uid          : chr  "s:20~l:28~a:3916387" "s:20~l:28~a:3139477" "s:20~l:28~a:2580" "s:20~l:28~a:2577417" ...
 $ guid         : chr  "7d76fbb11c5ed9f4954fcad43f720ae2" "37d87523280a9d4a0adb22cfc6d3619c" "a3d4f4473aef111aee5c4909a8e70a7c" "5f09781b6b0b7325049ba91e60d794e6" ...
 $ type         : chr  "football" "football" "football" "football" ...
 $ firstName    : chr  "Lamar" "Patrick" "Drew" "Dak" ...
 $ lastName     : chr  "Jackson" "Mahomes" "Brees" "Prescott" ...
 $ displayName  : chr  "Lamar Jackson" "Patrick Mahomes" "Drew Brees" "Dak Prescott" ...
 $ shortName    : chr  "L. Jackson" "P. Mahomes" "D. Brees" "D. Prescott" ...
 $ debutYear    : int  2018 2017 2001 2016 2012 2009 2017 2005 2012 2014 ...
 $ links        :List of 30
 $ headshot     :'data.frame':	30 obs. of  2 variables:
 $ position     :'data.frame':	30 obs. of  7 variables:
 $ status       :'data.frame':	30 obs. of  4 variables:
 $ age          : int  23 24 41 26 31 32 24 37 31 29 ...
 $ teamName     : chr  "Ravens" "Chiefs" "Saints" "Cowboys" ...
 $ teamShortName: chr  "BAL" "KC" "NO" "DAL" ...
 $ teams        :List of 30
 $ slug         : chr  "lamar-jackson" "patrick-mahomes" "drew-brees" "dak-prescott" ...
 $ teamId       : chr  "33" "12" "18" "6" ...
 $ teamUId      : chr  "s:20~l:28~t:33" "s:20~l:28~t:12" "s:20~l:28~t:18" "s:20~l:28~t:6" ...
```

</div>


Now there's still some sticky situations here, namely that some of the columns are list columns or even listed dataframes themselves. We'll deal with that a little bit later.

### Access the lists

We can change our 3rd call to `categories` instead of `athlete` to check out the other object of length 30. We see it is actually 30 1x4 dataframes!

<div class="layout-chunk" data-layout="l-body">

```r
# json -> list --> dataframe 
raw_json$athletes$categories %>% str(max.level = 1)
```

```
List of 30
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
 $ :'data.frame':	1 obs. of  4 variables:
```

</div>


We could check out the first dataframe like so, but we see that this dataframe actually has additional list columns, and the name/display columns are not very helpful. I'm much more interested in the totals and ranks columns as they have length 10.

<div class="layout-chunk" data-layout="l-body">

```r
# json -> list -> dataframe -> dataframe w/ list columns!
raw_json$athletes$categories[[1]]
```

```
     name displayName
1 general    General 
                                                    totals
1 81.8, 63.1, 613, 103.7, 55.0, 39.1, 0.0, 2.2, 81.1, -7.4
                         ranks
1 1, -, -, -, -, -, -, -, -, -
```

</div>


So let's check out the 3rd column and what is in it. Now if you're like me, this is starting to feel a bit hairy! We're 6 levels deep into one object and this is just 1 output of a total of 30!

Stick with me for one more example and then we'll get into `purrr`!

<div class="layout-chunk" data-layout="l-body">

```r
raw_json$athletes$categories[[1]][3][[1]]
```

```
[[1]]
 [1] "81.8"  "63.1"  "613"   "103.7" "55.0"  "39.1"  "0.0"   "2.2"  
 [9] "81.1"  "-7.4" 
```

</div>


So we know:  
- The QB names and teams (`raw_json$athletes$athlete`)  
- Their stats are in a different part of the `JSON` file (`aw_json$athletes$categories`)  

If you wanted to you could combine the `athlete` dataframe with their stats with a `for loop`. There are additional way of optimizing this (potentially convert to matrix and then to data.frame), but I just want to show that it's possible and fairly readable! An example with `lapply` is below as well. Note that since we're not pre-allocating our data.frame, this is likely the slowest method. It's ok for our 30 iteration example, but is likely not the best strategy for large `JSON` files.

<div class="layout-chunk" data-layout="l-body">

```r
df_interest <- raw_json$athletes$athlete[c("displayName", "teamName", "teamShortName")]

length_df <- nrow(df_interest)

pbp_out <- data.frame()

category_names <- raw_json[["categories"]][["labels"]][[1]]

for (i in 1:length_df){
  # grab each QBs stats and convert to a vector of type double
  raw_vec <- as.double(raw_json$athletes$categories[[i]]$totals[[1]])
  
  # split each stat into it's own list with the proper name
  split_vec <- split(raw_vec, category_names)
  
  # convert the list into a dataframe 
  pbp_df_loop <- cbind.data.frame(split_vec)
  
  # combine the 30 QB's stats into the empty data.frame
  pbp_out <- rbind(pbp_out, pbp_df_loop)
}

# combine our loop-created df w/ the QB names/team
final_loop_df <- cbind(df_interest, pbp_out)

# take a peek at the result!
glimpse(final_loop_df)
```

```
Rows: 30
Columns: 13
$ displayName   <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Bre…
$ teamName      <chr> "Ravens", "Chiefs", "Saints", "Cowboys", "Sea…
$ teamShortName <chr> "BAL", "KC", "NO", "DAL", "SEA", "DET", "HOU"…
$ EXP           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ PA            <dbl> 63.1, 52.4, 31.3, 44.1, 39.1, 24.9, 38.5, 26.…
$ PAS           <dbl> 55.0, 71.6, 53.1, 70.7, 58.3, 44.5, 52.0, 47.…
$ PEN           <dbl> 2.2, 5.0, 1.9, 2.6, 1.5, 1.9, 1.4, 3.7, 2.3, …
$ QBP           <dbl> 613, 585, 419, 690, 674, 353, 662, 620, 374, …
$ QBR           <dbl> 81.1, 78.0, 74.2, 71.2, 69.4, 73.1, 69.5, 64.…
$ RUN           <dbl> 39.1, 14.3, 1.6, 10.0, 10.6, 1.6, 19.8, 6.3, …
$ SAC           <dbl> -7.4, -6.5, -6.0, -9.7, -20.6, -8.0, -18.5, -…
$ TOT           <dbl> 103.7, 97.3, 62.6, 93.1, 90.9, 56.1, 91.6, 70…
$ TQBR          <dbl> 81.8, 76.3, 71.7, 70.2, 69.8, 69.6, 68.7, 66.…
```

</div>


Let's try this again, but with a function and iterating that function with `lapply`.

<div class="layout-chunk" data-layout="l-body">

```r
# extract the core name dataframe
df_interest <- raw_json$athletes$athlete[c("displayName", "teamName", "teamShortName")]

# how many rows?
length_df <- nrow(df_interest)

# category names again
category_names <- raw_json[["categories"]][["labels"]][[1]]

# create a function to apply
qbr_stat_fun <- function(qb_num){
  # grab each QBs stats and convert to a vector of type double
  raw_vec <- as.double(raw_json$athletes$categories[[qb_num]]$totals[[1]])
  
  # split each stat into it's own list with the proper name
  split_vec <- split(raw_vec, category_names)
  
  # return the lists
  split_vec
}

# use apply to generate list of lists
list_qbr_stats <- lapply(1:length_df, qbr_stat_fun)

# Combine the lists into a dataframe
list_pbp_df <- do.call("rbind.data.frame", list_qbr_stats)

# cbind the names with the stats
cbind(df_interest, list_pbp_df) %>% glimpse()
```

```
Rows: 30
Columns: 13
$ displayName   <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Bre…
$ teamName      <chr> "Ravens", "Chiefs", "Saints", "Cowboys", "Sea…
$ teamShortName <chr> "BAL", "KC", "NO", "DAL", "SEA", "DET", "HOU"…
$ EXP           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ PA            <dbl> 63.1, 52.4, 31.3, 44.1, 39.1, 24.9, 38.5, 26.…
$ PAS           <dbl> 55.0, 71.6, 53.1, 70.7, 58.3, 44.5, 52.0, 47.…
$ PEN           <dbl> 2.2, 5.0, 1.9, 2.6, 1.5, 1.9, 1.4, 3.7, 2.3, …
$ QBP           <dbl> 613, 585, 419, 690, 674, 353, 662, 620, 374, …
$ QBR           <dbl> 81.1, 78.0, 74.2, 71.2, 69.4, 73.1, 69.5, 64.…
$ RUN           <dbl> 39.1, 14.3, 1.6, 10.0, 10.6, 1.6, 19.8, 6.3, …
$ SAC           <dbl> -7.4, -6.5, -6.0, -9.7, -20.6, -8.0, -18.5, -…
$ TOT           <dbl> 103.7, 97.3, 62.6, 93.1, 90.9, 56.1, 91.6, 70…
$ TQBR          <dbl> 81.8, 76.3, 71.7, 70.2, 69.8, 69.6, 68.7, 66.…
```

</div>


Now, I typically don't suggest using a `for loop` as per [Advanced R](https://adv-r.hadley.nz/control-flow.html#loops) this approach can be prone to some common pitfalls which can lead to performance deficits or side effects. Similarily, the `apply` family of functions are very powerful but for [some folks](https://jennybc.github.io/purrr-tutorial/bk01_base-functions.html) they find that it doesn't quite fit with their mental model or is inconsistent in the expected output. 

As an alternative to loops and/or `apply`, we can use `purrr`, AND `purrr` can also help us a lot with actually parsing through the `JSON` itself! I also think that other `tidyverse` tools like `tidyr` for `unnest_wider` and `unpack`/`hoist` are useful here as alternative strategies!

# Enter `purrr`

`purrr` is usually thought of for using functional programming as alternatives to `for loops` and for the concept of "Iteration without repetition". Overviews of `purrr` are covered a bit deeper in [R4DS](https://r4ds.had.co.nz/iteration.html) and in one of my previous [blog posts](https://themockup.blog/posts/2018-12-11-functional-progamming-in-r-with-purrr/).

## `purrr::pluck()`

The first function from `purrr` we'll use is `pluck`, which provides a consistent and generalized form of `[[`. This allows you to quickly move through lists and nested lists.

Let's get back to our QB dataframe with `pluck`! There are still a lot of columns we don't need, but we'll get rid of those when we put all the data together.

<div class="layout-chunk" data-layout="l-body">

```r
raw_json %>% 
  # equivalent to raw_json[["athletes"]][["athlete"]]
  purrr::pluck("athletes", "athlete") %>% 
  glimpse()
```

```
Rows: 30
Columns: 20
$ id            <chr> "3916387", "3139477", "2580", "2577417", "148…
$ uid           <chr> "s:20~l:28~a:3916387", "s:20~l:28~a:3139477",…
$ guid          <chr> "7d76fbb11c5ed9f4954fcad43f720ae2", "37d87523…
$ type          <chr> "football", "football", "football", "football…
$ firstName     <chr> "Lamar", "Patrick", "Drew", "Dak", "Russell",…
$ lastName      <chr> "Jackson", "Mahomes", "Brees", "Prescott", "W…
$ displayName   <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Bre…
$ shortName     <chr> "L. Jackson", "P. Mahomes", "D. Brees", "D. P…
$ debutYear     <int> 2018, 2017, 2001, 2016, 2012, 2009, 2017, 200…
$ links         <list> [<data.frame[7 x 7]>, <data.frame[7 x 7]>, <…
$ headshot      <df[,2]> <data.frame[23 x 2]>
$ position      <df[,7]> <data.frame[23 x 7]>
$ status        <df[,4]> <data.frame[23 x 4]>
$ age           <int> 23, 24, 41, 26, 31, 32, 24, 37, 31, 29, 27, 2…
$ teamName      <chr> "Ravens", "Chiefs", "Saints", "Cowboys", "Sea…
$ teamShortName <chr> "BAL", "KC", "NO", "DAL", "SEA", "DET", "HOU"…
$ teams         <list> [<data.frame[1 x 2]>, <data.frame[1 x 2]>, <…
$ slug          <chr> "lamar-jackson", "patrick-mahomes", "drew-bre…
$ teamId        <chr> "33", "12", "18", "6", "26", "8", "34", "15",…
$ teamUId       <chr> "s:20~l:28~t:33", "s:20~l:28~t:12", "s:20~l:2…
```

</div>


What about that pesky headshot column that reports as a list dataframe? We can just add an additional depth argument with `"headshot"` and see that it gives us a URL to the QB's photo and a repeat of the QB's name. We'll use this a bit later to get the URL only.

<div class="layout-chunk" data-layout="l-body">

```r
raw_json %>% 
  # equivalent to raw_json[["athletes"]][["athlete"]][["headshot"]]
  purrr::pluck("athletes", "athlete", "headshot") %>% 
  glimpse()
```

```
Rows: 30
Columns: 2
$ href <chr> "https://a.espncdn.com/i/headshots/nfl/players/full/39…
$ alt  <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Brees", "Dak…
```

</div>


## `purrr::map`

So `pluck` allows us to quickly get to the data of interest, but what about replacing our `for loop` to get at the vectors for each of the QB's individual stats? `map()` can help us accomplish this!

### Define a function

Again, `purrr` is used for functional programming, so we need to define a function to iterate with. We'll define this as `get_qbr_data()` and test it out! It gets us a nicely extracted named numeric vector. The names are useful as when we go to `unnest_wider()` the dataset it will automatically assign the column names for us. 

<div class="layout-chunk" data-layout="l-body">

```r
# get names of the QBR categories with pluck
category_names <- pluck(raw_json, "categories", "labels", 1)

category_names
```

```
 [1] "TQBR" "PA"   "QBP"  "TOT"  "PAS"  "RUN"  "EXP"  "PEN"  "QBR" 
[10] "SAC" 
```

```r
# Get the QBR stats by each player (row_n = row number of player in the df)
get_qbr_data <- function(row_n) {
  purrr::pluck(raw_json, "athletes", "categories", row_n, "totals", 1) %>% 
    # convert from character to double
    as.double() %>% 
    # assign names from category
    set_names(nm = category_names)
}

# test the function
get_qbr_data(1)
```

```
 TQBR    PA   QBP   TOT   PAS   RUN   EXP   PEN   QBR   SAC 
 81.8  63.1 613.0 103.7  55.0  39.1   0.0   2.2  81.1  -7.4 
```

</div>


Note, while this looks like a 1x10 dataframe, it's still just a vector with name attributes.

<div class="layout-chunk" data-layout="l-body">

```r
# What type?
get_qbr_data(1) %>% str()
```

```
 Named num [1:10] 81.8 63.1 613 103.7 55 ...
 - attr(*, "names")= chr [1:10] "TQBR" "PA" "QBP" "TOT" ...
```

</div>


# Put it all together

We can use our defined function, `purrr::pluck()` and `purrr::map` to build our final dataframe!

Let's start by extracting the core dataframe with player name, team name, and for extra fun, the headshot which is a listed dataframe column!

<div class="layout-chunk" data-layout="l-body">

```r
# create the dataframe and tidy it up
pbp_df <- pluck(raw_json, "athletes", "athlete") %>%
  # convert to tibble
  as_tibble() %>%
  # select columns of interest
  select(displayName, teamName:teamShortName, headshot)

# print it
pbp_df
```

```
# A tibble: 30 x 4
   displayName  teamName teamShortName headshot$href           $alt   
   <chr>        <chr>    <chr>         <chr>                   <chr>  
 1 Lamar Jacks… Ravens   BAL           https://a.espncdn.com/… Lamar …
 2 Patrick Mah… Chiefs   KC            https://a.espncdn.com/… Patric…
 3 Drew Brees   Saints   NO            https://a.espncdn.com/… Drew B…
 4 Dak Prescott Cowboys  DAL           https://a.espncdn.com/… Dak Pr…
 5 Russell Wil… Seahawks SEA           https://a.espncdn.com/… Russel…
 6 Matthew Sta… Lions    DET           https://a.espncdn.com/… Matthe…
 7 Deshaun Wat… Texans   HOU           https://a.espncdn.com/… Deshau…
 8 Ryan Fitzpa… Dolphins MIA           https://a.espncdn.com/… Ryan F…
 9 Ryan Tanneh… Titans   TEN           https://a.espncdn.com/… Ryan T…
10 Derek Carr   Raiders  OAK           https://a.espncdn.com/… Derek …
# … with 20 more rows
```

</div>


Now we can use our `get_qbr_data()` to do just that and grab the data from the `categories`/`totals` portion of the JSON. Almost done, and the dataframe is already looking great. All that is left is dealing with that pesky headshot column!

<div class="layout-chunk" data-layout="l-body">

```r
# Take our pbp_df
wide_pbp_df <- pbp_df %>%
  # and then map across it to get the QBR data
  mutate(data = map(row_number(), get_qbr_data)) %>% 
  # and then unnest the list column we created
  unnest_wider(data)

wide_pbp_df %>% 
  glimpse()
```

```
Rows: 30
Columns: 14
$ displayName   <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Bre…
$ teamName      <chr> "Ravens", "Chiefs", "Saints", "Cowboys", "Sea…
$ teamShortName <chr> "BAL", "KC", "NO", "DAL", "SEA", "DET", "HOU"…
$ headshot      <df[,2]> <data.frame[23 x 2]>
$ TQBR          <dbl> 81.8, 76.3, 71.7, 70.2, 69.8, 69.6, 68.7, 66.…
$ PA            <dbl> 63.1, 52.4, 31.3, 44.1, 39.1, 24.9, 38.5, 26.…
$ QBP           <dbl> 613, 585, 419, 690, 674, 353, 662, 620, 374, …
$ TOT           <dbl> 103.7, 97.3, 62.6, 93.1, 90.9, 56.1, 91.6, 70…
$ PAS           <dbl> 55.0, 71.6, 53.1, 70.7, 58.3, 44.5, 52.0, 47.…
$ RUN           <dbl> 39.1, 14.3, 1.6, 10.0, 10.6, 1.6, 19.8, 6.3, …
$ EXP           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ PEN           <dbl> 2.2, 5.0, 1.9, 2.6, 1.5, 1.9, 1.4, 3.7, 2.3, …
$ QBR           <dbl> 81.1, 78.0, 74.2, 71.2, 69.4, 73.1, 69.5, 64.…
$ SAC           <dbl> -7.4, -6.5, -6.0, -9.7, -20.6, -8.0, -18.5, -…
```

</div>


We can use `pluck` one more time to get the `href` column from within `headshot`, which allows us to extract just the URL and not the repeated player name from that list-dataframe column (`headshot`). `unpack()` is also really nice normally but since the `headshot` dataframe has a duplicate column, it requires additional dropping of columns.

<div class="layout-chunk" data-layout="l-body">

```r
final_pluck <- wide_pbp_df %>% 
  # we can pluck just the `href` column
  mutate(headshot = pluck(headshot, "href"))

final_unpack <- wide_pbp_df %>% 
  unpack(headshot) %>% 
  # unpack includes the alt column as well
  select(everything(), headshot = href, -alt)

final_base <- wide_pbp_df %>% 
  # we can use traditional base R column selection
  mutate(headshot = headshot[["href"]])

final_join <- wide_pbp_df %>% 
  # could also do a join
  left_join(wide_pbp_df$headshot, by = c("displayName" = "alt")) %>% 
  # but have to drop and do additional cleanup
  select(-headshot, displayName:teamShortName, headshot = href, TQBR:SAC)

# all are the same!
c(all.equal(final_pluck, final_unpack),
  all.equal(final_pluck, final_base),
  all.equal(final_pluck, final_join))
```

```
 [1] "TRUE"                                                 
 [2] "TRUE"                                                 
 [3] "Names: 11 string mismatches"                          
 [4] "Component 4: Modes: character, numeric"               
 [5] "Component 4: target is character, current is numeric" 
 [6] "Component 5: Mean relative difference: 0.776347"      
 [7] "Component 6: Mean relative difference: 29.69477"      
 [8] "Component 7: Mean relative difference: 0.8976462"     
 [9] "Component 8: Mean relative difference: 0.3792384"     
[10] "Component 9: Mean relative difference: 0.8295856"     
[11] "Component 10: Mean relative difference: 1"            
[12] "Component 11: Mean absolute difference: 3.273333"     
[13] "Component 12: Mean relative difference: 16.38086"     
[14] "Component 13: Mean relative difference: 1.242325"     
[15] "Component 14: Modes: numeric, character"              
[16] "Component 14: target is numeric, current is character"
```

```r
glimpse(final_pluck)
```

```
Rows: 30
Columns: 14
$ displayName   <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Bre…
$ teamName      <chr> "Ravens", "Chiefs", "Saints", "Cowboys", "Sea…
$ teamShortName <chr> "BAL", "KC", "NO", "DAL", "SEA", "DET", "HOU"…
$ headshot      <chr> "https://a.espncdn.com/i/headshots/nfl/player…
$ TQBR          <dbl> 81.8, 76.3, 71.7, 70.2, 69.8, 69.6, 68.7, 66.…
$ PA            <dbl> 63.1, 52.4, 31.3, 44.1, 39.1, 24.9, 38.5, 26.…
$ QBP           <dbl> 613, 585, 419, 690, 674, 353, 662, 620, 374, …
$ TOT           <dbl> 103.7, 97.3, 62.6, 93.1, 90.9, 56.1, 91.6, 70…
$ PAS           <dbl> 55.0, 71.6, 53.1, 70.7, 58.3, 44.5, 52.0, 47.…
$ RUN           <dbl> 39.1, 14.3, 1.6, 10.0, 10.6, 1.6, 19.8, 6.3, …
$ EXP           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ PEN           <dbl> 2.2, 5.0, 1.9, 2.6, 1.5, 1.9, 1.4, 3.7, 2.3, …
$ QBR           <dbl> 81.1, 78.0, 74.2, 71.2, 69.4, 73.1, 69.5, 64.…
$ SAC           <dbl> -7.4, -6.5, -6.0, -9.7, -20.6, -8.0, -18.5, -…
```

</div>


So that's it! A few different approaches to get to the same result, some of the ways to interact with nested JSON, and doing it all with either mostly base or `tidyverse`. So the next time you interact with JSON, I hope you feel better equipped to work with it!

# One more example

If you are using the latest version of `tidyr` (1.1) - check out Hadley's approach to this!

Note that he is using `jsonlite::read_json()` rather than `fromJSON`, this doesn't simplify and keeps everything as it's natural list-state. With `tidyr::unnest()` and `tidyr::hoist()` this is easy to work with!

Don't forget to check out the [rectangling guide](https://tidyr.tidyverse.org/articles/rectangle.html) from the `tidyverse` team.

<div class="layout-chunk" data-layout="l-body">

```r
library(tidyverse)
library(jsonlite)

# link to the API output as a JSON file
url_json <- "https://site.web.api.espn.com/apis/fitt/v3/sports/football/nfl/qbr?region=us&lang=en&qbrType=seasons&seasontype=2&isqualified=true&sort=schedAdjQBR%3Adesc&season=2019"

# get the raw json into R
raw_json_list <- jsonlite::read_json(url_json)

# get names of the QBR categories
category_names <- pluck(raw_json_list, "categories", 1, "labels")

# create tibble out of athlete objects
athletes <- tibble(athlete = pluck(raw_json_list, "athletes"))

qbr_hadley <- athletes %>% 
  unnest_wider(athlete) %>% 
  hoist(athlete, "displayName", "teamName", "teamShortName") %>% 
  unnest_longer(categories) %>% 
  hoist(categories, "totals") %>% 
  mutate(totals = map(totals, as.double),
         totals = map(totals, set_names, category_names)) %>% 
  unnest_wider(totals) %>% 
  hoist(athlete, headshot = list("headshot", "href")) %>% 
  select(-athlete, -categories)

# Is it the same as my version?
all.equal(final_pluck, qbr_hadley)
```

```
[1] TRUE
```

</div>



# TLDR

<div class="layout-chunk" data-layout="l-body">

```r
library(tidyverse)
library(jsonlite)

# link to the API output as a JSON file
url_json <- "https://site.web.api.espn.com/apis/fitt/v3/sports/football/nfl/qbr?region=us&lang=en&qbrType=seasons&seasontype=2&isqualified=true&sort=schedAdjQBR%3Adesc&season=2019"

# get the raw json into R
raw_json <- jsonlite::fromJSON(url_json)

# get names of the QBR categories
category_names <- pluck(raw_json, "categories", "labels", 1)

# Get the QBR stats by each player (row_n = player)
get_qbr_data <- function(row_n) {
  purrr::pluck(raw_json, "athletes", "categories", row_n, "totals", 1) %>% 
    as.double() %>% 
    set_names(nm = category_names)
}

# create the dataframe and tidy it up
ex_output <- pluck(raw_json, "athletes", "athlete") %>%
  as_tibble() %>%
  select(displayName, teamName:teamShortName, headshot) %>%
  mutate(data = map(row_number(), get_qbr_data)) %>% 
  unnest_wider(data) %>% 
  mutate(headshot = pluck(headshot, "href"))

glimpse(ex_output)
```

```
Rows: 30
Columns: 14
$ displayName   <chr> "Lamar Jackson", "Patrick Mahomes", "Drew Bre…
$ teamName      <chr> "Ravens", "Chiefs", "Saints", "Cowboys", "Sea…
$ teamShortName <chr> "BAL", "KC", "NO", "DAL", "SEA", "DET", "HOU"…
$ headshot      <chr> "https://a.espncdn.com/i/headshots/nfl/player…
$ TQBR          <dbl> 81.8, 76.3, 71.7, 70.2, 69.8, 69.6, 68.7, 66.…
$ PA            <dbl> 63.1, 52.4, 31.3, 44.1, 39.1, 24.9, 38.5, 26.…
$ QBP           <dbl> 613, 585, 419, 690, 674, 353, 662, 620, 374, …
$ TOT           <dbl> 103.7, 97.3, 62.6, 93.1, 90.9, 56.1, 91.6, 70…
$ PAS           <dbl> 55.0, 71.6, 53.1, 70.7, 58.3, 44.5, 52.0, 47.…
$ RUN           <dbl> 39.1, 14.3, 1.6, 10.0, 10.6, 1.6, 19.8, 6.3, …
$ EXP           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
$ PEN           <dbl> 2.2, 5.0, 1.9, 2.6, 1.5, 1.9, 1.4, 3.7, 2.3, …
$ QBR           <dbl> 81.1, 78.0, 74.2, 71.2, 69.4, 73.1, 69.5, 64.…
$ SAC           <dbl> -7.4, -6.5, -6.0, -9.7, -20.6, -8.0, -18.5, -…
```

</div>

