# Prepare environmental data

#################################################################################################################
## source "01_1readGeo_CM_zone_APSIM.R" function and get weather data 
#################################################################################################################
source("~/agwise-potentialyield/dataops/potentialyield/Script/generic/APSIM/01_readGeo_CM_zone_APSIM.R")

#################################################################################################################
## Create soil and weather data in APSIM format for AOI data
#################################################################################################################
pathIn_zone <- T
level2 <- NA
Depth <- c(5, 15, 30, 60, 100, 200)
AOI <- TRUE
season <- 1
country <- "Rwanda"
useCaseName <- "RAB"
Crop <- "Maize"

varietyid <- "Early"
# varietyid <- "Dekalb_XL82"
# varietyid <- "Katumani"

countryShp <- geodata::gadm(country, level = 2, path='.')
prov <- unique(countryShp$NAME_1)

path.to.extdata <- paste("/home/jovyan/agwise-potentialyield/dataops/potentialyield/Data/useCase_", 
                                            country, "_",useCaseName, "/", Crop, "/transform/APSIM/AOI/", sep="")

log_file <- paste(path.to.extdata,"progress_log_readGeo_CM_APSIM.txt",sep='/')

if (file.exists(log_file)) {
  file.remove(log_file)
}

start_time <- Sys.time()
for (i in 1:length(prov)){
  geoData_AOI <- readGeo_CM_zone_APSIM(country = country, 
                                       useCaseName = useCaseName, Crop = Crop, 
                                       AOI = AOI, season = season, 
                                       zone = prov[i], level2 = level2, 
                                       varietyid = varietyid, 
                                       pathIn_zone = pathIn_zone, 
                                       Depth = Depth)
  
  # message <- paste("Province finished:", i,Sys.time())
  # cat(message, "\n", file = log_file, append = TRUE)
}

end_time <- Sys.time()
duration <- end_time - start_time
cat(duration, "\n", file = log_file, append = TRUE)
