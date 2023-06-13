# wandeR
## About the package
The wandeR package is an R package for spatial modelling, particularly in the context of connectivity or dispersal activities (e.g. the movement of animals, people, fishing boats, cars, etc.).

## Installation
``` r
devtools::install_github("EdSacre/wandeR")
```

## Getting Started
### Load packages
```{r}
library(wandeR)
library(raster)
```

### Import some testing dataset
The coral raster shows coral habitat around Zanzibar and Pemba Island.
The zanzibar raster show all ocean areas around Zanzibar.
We want to model the connectivity of corals in the area, assuming the can only
disperse through these ocean areas.
```{r, out.width="680px", out.height="300px", fig.width=10, fig.height=4, fig.align = 'center'}
coral <- wander_data("coral")
zanzibar <- wander_data("zanzibar")
plot(stack(coral, zanzibar), axes = FALSE)
```

### Examine dispersal kernel options
Here on the left we see a negative exponential distribution, which defines the dispersal kernel as decaying in
an exponential fashion. In other words, like likelihood of successful dispersal declines exponentially with distance between sites.
On the right is a beta distribution, which provides a slightly different definition for dispersal kernel.
Instead, the probability of successful dispersal is low at short distances between sites, then rapidly increases for intermediate
distances, and then declines again.
```{r, out.width="680px", out.height="300px", fig.width=10, fig.height=4}
par(mfrow=c(1,2))
wander_kernel(kernel = "neg_exp")
wander_kernel(kernel = "beta")
```

Here we can see the effects that changes in the kernel parameters have on the shape of the kernel
```{r, out.width="680px", out.height="300px", fig.width=10, fig.height=4}
par(mfrow=c(1,3))
wander_kernel(kernel = "neg_exp", t = 0.1)
wander_kernel(kernel = "neg_exp", t = 0.5)
wander_kernel(kernel = "neg_exp", t = 0.9)
```

### Run the connectivity models
This model calculates the connectivity of each cell to the coral habitats. 
Cells with a high value are highly connected to many coral reef habitats,
and, therefore, likely serve as a "hub" or connectivity hotspot.
```{r, out.width="400px", out.height="400px", fig.width=7, fig.height=7, fig.align = 'center'}
conmod <- connect(habitats = coral, surface = zanzibar, maxdist = 50000, nthreads = 1)
plot(conmod, axes = FALSE)
```
![Alt text](inst/images/connect.JPG)

Now we will run the "highway" connectivity, which models highways or corridors 
through which species are predicted to most often travel. This model can take a
long time to calculate, so we will use a subset of the coral data with only a few
habitat cells.
```{r, out.width="400px", out.height="400px", fig.width=7, fig.height=7, fig.align = 'center'}
coral_subset <- wander_data("coral_subset")
plot(coral_subset, axes = FALSE)
```

Now, let's run the highway model.
```{r, out.width="400px", out.height="400px", fig.width=7, fig.height=7, fig.align = 'center'}
highmod <- highway(habitats = coral_subset, surface = zanzibar, maxdist = 200000, nthreads = 1)
coral_subset[coral_subset == 0] <- NA 
coral_point <- raster::rasterToPoints(coral_subset, spatial = TRUE)
plot(highmod, axes = FALSE)
plot(coral_point, pch = 19, cex = 0.5, add = TRUE)
```

### Usage

