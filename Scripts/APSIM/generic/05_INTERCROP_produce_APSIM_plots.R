# Produce individual EXTE scatter plots and maps for best Sow Date and highest yields per location for INTERCROPS

# Sourcing required packages -------------------------------------------
packages_required <- c("ggplot2", "tidyverse", "ggridges", "patchwork", "Rmisc", 
                       "terra", "cowplot", "foreach", "doParallel", "future",
                       "future.apply", "sf", "arrow", "geodata", "tools")

installed_packages <- packages_required %in% rownames(installed.packages())
if(any(installed_packages == FALSE)){
  install.packages(packages_required[!installed_packages])
}

# load required packages
suppressWarnings(suppressPackageStartupMessages(invisible(lapply(packages_required, library, character.only = TRUE))))

#' Generate APSIM Intercrop Plots for Crop Simulation Results
#'
#' This function processes APSIM simulation results for intercrops and produces plots
#' to visualize crop yields by variety, sowing date, and location. It can also produce
#' EXTE plots for individual simulation files if requested.
#'
#' @param results A data frame or NULL (ignored; function reads parquet file based on season and path).
#' @param country The country name used to retrieve boundary data.
#' @param variety The crop variety to filter results by.
#' @param useCaseName A label describing the use case or scenario.
#' @param Crops A vector of crop names; the first crop is treated as the main crop.
#' @param season Integer indicating the season number (default = 1).
#' @param main_crop_sowing_date_name String specifying the column name in results for the main crop sowing date (default = "SowDate").
#' @param produce_EXTE_plots Logical; if TRUE, EXTE plots for individual simulation files are produced and saved (default = FALSE).
#' @param yield_column Optional string; name of the column to treat as yield (renames it to 'Yield').
#'
#' @return None returned. The function reads APSIM results, processes them, and saves plots to disk:
#'   - EXTE plots per simulation file (if `produce_EXTE_plots = TRUE`)
#'   - Summary plots showing best sowing dates by location
#'   - Summary plots showing highest yields by location
#'
#' @details
#' The function:
#'   - Reads APSIM results from a parquet file based on `season`, `country`, and `useCaseName`.
#'   - Optionally renames the specified yield column to 'Yield'.
#'   - Filters results for the selected variety and ensures at least 5 simulations per file.
#'   - Converts sowing dates to Date and factor formats for plotting.
#'   - Produces EXTE plots for each simulation file if requested.
#'   - Computes top yields by location and produces summary plots showing best sowing dates and highest yields.
#'   - Saves all plots to `pathOut`, organized by country, use case, crop, and season.
#'
#' @examples
#' \dontrun{
#' INTERCROP_apsim.plots(
#'   results = NULL,
#'   country = "Rwanda",
#'   variety = "Short",
#'   useCaseName = "RAB",
#'   Crops = c("Maize", "Peanut"),
#'   season = 1,
#'   main_crop_sowing_date_name = "MSD",
#'   produce_EXTE_plots = TRUE
#' )
#' }

apsim.plots<- function(country, variety, useCaseName, Crops,
                                 expfile_name,
                                 main_crop_sowing_date_name = "SowDate",
                                 produce_EXTE_plots=FALSE, yield_column=NULL){
  Crop <- Crops[1]
  clean_expfile_name <- tools::file_path_sans_ext(expfile_name)
  results <- read_parquet(paste0("/home/jovyan/agwise-cropping-innovation/Data/useCase_Rwanda_RAB/Maize/result/APSIM/AOI/",
                                 clean_expfile_name,
                                 ".parquet"))
  if (!is.null(yield_column) && (yield_column %in% names(results))){
    results$Yield <- NULL
    print(paste(yield_column, "selected as Yield."))
    results <- results %>% dplyr::rename(Yield = !!yield_column)
  }
  
  results <- results %>%
    dplyr::rename(SowDate = !!sym(main_crop_sowing_date_name)) %>%
    filter(Variety == variety) %>%
    group_by(file_name) %>%
    filter(n() >= 5) %>%
    ungroup()
  
  unique_files <- unique(results$file_name)
  
  smdata <- results %>%
    filter(file_name == unique_files[1]) %>%
    select(SimulationID, Yield, SowDate) %>%
    arrange(SimulationID)
  
  results <- results %>%
    mutate(
      SowDate_date = as.Date(paste(SowDate, "2020"), format = "%d %b %Y"),
      SowDate = format(SowDate_date, "%d %b"),
      SowDate_factor = factor(SowDate, levels = format(sort(unique(SowDate_date)), "%d %b"))
    )
  # results <- results %>%
  #   mutate(
  #     SowDate_date = as.Date(paste0(SowDate, "-2020"), format = "%d-%b-%Y"),
  #     SowDate_factor = factor(SowDate, levels = unique(SowDate[order(SowDate_date)]))
  #   )
  
  if (produce_EXTE_plots){  
    for (fn in unique_files) {
      p <- results %>%
        filter(file_name == fn) %>%
        ggplot(aes(x = SowDate_factor, y = Yield)) +
        geom_point(na.rm = TRUE) +
        ggtitle({
          path_parts <- str_split(fn, "/")[[1]]
          n <- length(path_parts)
          location <- path_parts[n-2]
          experiment <- path_parts[n-1]
          paste0("Yield for ", location, " (", experiment, ")")
        }) +
        xlab("Sow Date") +
        theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
      
      path_parts <- str_split(fn, "/")[[1]]
      n <- length(path_parts)
      location <- path_parts[n-2]
      EXTE <- path_parts[n-1]
      
      outfile <- paste0("yield_", clean_expfile_name, "_", location, "_", EXTE, ".png")
      
      outdir <- dirname(fn)
      
      parts <- str_split(outdir, "/")[[1]]
      new_parts <- parts[1:(length(parts) - 3)]
      
      outdir <- paste0(paste(new_parts, collapse = "/"), "/")
      outdir <- sub("/transform/", "/result/", outdir)
      outdir <- paste0(outdir, "EXTE_", clean_expfile_name)
      
      if (!dir.exists(outdir)) {
        dir.create(outdir, recursive = TRUE)
      }
      

      ggsave(
        filename = file.path(outdir, outfile),
        plot = p,
        width = 8,
        height = 5
      )
      
    }
  }
  
  # glimpse(results)
  
  results <- results %>% 
    dplyr::rename(Longitude = longitude,
                  Latitude = latitude)
  
  final <- mutate(results, lonlat = paste0(Longitude, "_", Latitude))
  
  p_Win <- final  %>% 
    group_by(Longitude, Latitude)%>%
    arrange(desc(Yield)) %>% 
    slice(1:10) %>%
    as.data.frame() 
  
  pd <- final %>%
    group_by(Longitude, Latitude )%>%
    slice(which.max(Yield)) %>%
    as.data.frame() 
  
  country_ori <- country
  country <- geodata::gadm(country = country, level = 0, path = tempdir())
  country <- st_as_sf(country)
  
  p1 <- ggplot() + 
    geom_sf(data=country, fill = "white") +
    geom_point(data=pd, 
               aes(x=Longitude, y=Latitude, color= SowDate_factor), 
               size = 2) +
    labs(title = "Best Performing Sowing Date by Location",
         color = "Sowing Date")
  
  ggsave(paste0("/home/jovyan/agwise-cropping-innovation/Data/useCase_", country_ori, "_", useCaseName, "/", Crop, "/result/APSIM/", clean_expfile_name, "_best_sowdate_by_loc.png"),
         p1, width = 8, height = 6, dpi = 300)
  print(p1)

  p3 <- ggplot() + 
    geom_sf(data=country, fill = "white") +
    geom_point(data=pd, 
               aes(x=Longitude, y=Latitude, color= Yield), 
               size = 2) +
    labs(title = "Highest Yield by location")
  ggsave(paste0("/home/jovyan/agwise-cropping-innovation/Data/useCase_", country_ori, "_", useCaseName, "/", Crop, "/result/APSIM/", clean_expfile_name, "_highest_yield_by_loc.png"),
         p3, width = 8, height = 6, dpi = 300)
  print(p3)
}
