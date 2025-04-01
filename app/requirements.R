  # Checar paquetes necesarios
  list.of.packages <- c("echarts4r", "magrittr", "shiny")
  # Comparar output para instalar paquetes
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
  if(length(new.packages)) install.packages(new.packages)