###############################
## Produce plots and results ##
###############################

## Define experiment ##
# Experimental file name
# Experimental file name
# expfile_name <- "MaizeFactorialAugSep.apsimx"; cropping_system <- "monocrop"

# expfile_name <- "MaizePeanutIntercrop.apsimx"; cropping_system <- "intercrop"
# expfile_name <- "MaizeSoybeanIntercrop.apsimx"; cropping_system <- "intercrop"

# expfile_name <- "MaizePeanutRotation.apsimx"; cropping_system <- "rotation"
expfile_name <- "MaizeSoybeanRotation.apsimx"; cropping_system <- "rotation"

country <- "Rwanda"
useCaseName <- "RAB"

# Crops
main_Crop <- "Maize"
# sec_Crop <- "Peanut"
sec_Crop <- "Soybean"
Crops <- c(main_Crop, sec_Crop)

# Main crop sowing date name
main_crop_sowing_date_name <- "MSD"
yield_column <- NULL # Change this to change column for yield (otherwise Yield is used)

# Main and secondary crop cultivars
# main_Crop_varietyid <- "Early"  
# main_Crop_varietyid <- "Dekalb_XL82"  # Maize cultivar
main_Crop_varietyid <- "Katumani"  # Maize cultivar
# sec_Crop_varietyid <- "Florunner"  # Peanut cultivar
sec_Crop_varietyid <- "Soya791"  # Soybean cultivar
varietyids <- c(main_Crop_varietyid, sec_Crop_varietyid)

########################################
## Produce EXTE plots and simple maps ##
########################################
season <- 1
produce_EXTE_plots <- TRUE  # TRUE for producing scatter plots for each EXTE








# Source script and select function
script_to_source <- switch(cropping_system,
                           monocrop = "~/agwise-potentialyield/dataops/potentialyield/Script/generic/APSIM/05_MONOCROP_produce_APSIM_plots.R",
                           intercrop = "~/agwise-potentialyield/dataops/potentialyield/Script/generic/APSIM/05_INTERCROP_produce_APSIM_plots.R",
                           rotation = "~/agwise-potentialyield/dataops/potentialyield/Script/generic/APSIM/05_ROTATION_produce_APSIM_plots.R")

source(script_to_source)

arguments <- switch(cropping_system,
                    monocrop = list(
                      country = country, variety = NULL,
                      useCaseName = useCaseName, Crop = Crop,
                      expfile_name = expfile_name,
                      produce_EXTE_plots = produce_EXTE_plots,
                      yield_column = yield_column
                    ),
                    intercrop = list(
                      country = country, variety = NULL, 
                      useCaseName = useCaseName, Crops = Crops,
                      expfile_name = expfile_name,
                      produce_EXTE_plots = produce_EXTE_plots,
                      yield_column = yield_column,
                      main_crop_sowing_date_name = main_crop_sowing_date_name
                    ),
                    rotation = list(
                      country = country, variety = NULL, 
                      useCaseName = useCaseName, Crops = Crops,
                      expfile_name = expfile_name,
                      produce_EXTE_plots = produce_EXTE_plots,
                      yield_column = yield_column,
                      main_crop_sowing_date_name = main_crop_sowing_date_name
                    ))

for (v in varietyids){
  args <- arguments
  args$variety <- v
  do.call(apsim.plots, args)
}

########################################
## Produce ONI scatter plots and maps ##
########################################
zone_folder <- TRUE
level2_folder <- FALSE
AOI <- TRUE
Plot <- TRUE
justplot <- FALSE

season <- 1
short_variety = "Dekalb_XL82"  # Name of the first variety
medium_variety = "Dekalb_XL82"  # Name of the second variety
long_variety = "Dekalb_XL82"  # Name of the third variety

script_to_source <- switch(cropping_system,
                           monocrop = "~/agwise-potentialyield/dataops/potentialyield/Script/generic/APSIM/05_MONOCROP_produce_APSIM_plots.R",
                           intercrop = "~/agwise-potentialyield/dataops/potentialyield/Script/generic/APSIM/05_INTERCROP_produce_APSIM_plots.R",
                           rotation = "~/agwise-potentialyield/dataops/potentialyield/Script/generic/APSIM/05_ROTATION_produce_APSIM_plots.R")

source(script_to_source)

arguments <- switch(cropping_system,
                    monocrop = list(
                      country = country, useCaseName = useCaseName, Crop = Crop,
                      expfile_name = expfile_name, AOI = AOI, season = season,
                      Plot = Plot, short_variety = short_variety,
                      medium_variety = medium_variety, 
                      long_variety = long_variety, justplot = justplot
                    ),
                    intercrop = list(
                      country = country, useCaseName = useCaseName,
                      Crops = Crops, expfile_name = expfile_name, AOI = AOI,
                      season = season, Plot = Plot,
                      main_crop_sowing_date_name = main_crop_sowing_date_name, 
                      short_variety = short_variety, 
                      medium_variety = medium_variety,
                      long_variety = long_variety,
                      justplot = justplot
                    ),
                    rotation = list(
                      country = country, useCaseName = useCaseName,
                      Crops = Crops, expfile_name = expfile_name, AOI = AOI,
                      season = season, Plot = Plot,
                      main_crop_sowing_date_name = main_crop_sowing_date_name, 
                      short_variety = short_variety, 
                      medium_variety = medium_variety,
                      long_variety = long_variety,
                      justplot = justplot
                    ))


do.call(get_ONI, arguments)

