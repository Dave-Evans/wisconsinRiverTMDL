# scree plottin'
# assuming everything has already been run in aggregate_SSURGO.R
library(ggplot2)
library(reshape2)
library(stringr)
# library(rgdal)

net_soil_dir <- "T:/Projects/Wisconsin_River/GIS_Datasets/Soils"
mupoly_file <- 'MUPOLYGON__2mile_buffer_wMich_2014'
file_agg_mapunits <- "aggregated_soils_to_mapunit.txt" #aggregated to mus from step 1
file_agg_soil_units <- "aggregated_soil_units.txt"
file_mukey_hrugrp_lu <- "agg_unit_mukey_lu.txt"

# mupolygons <- readOGR(dsn=net_soil_dir, layer=mupoly_file)
agg_mapunits <- read.delim(paste(net_soil_dir, file_agg_mapunits,sep = '/'), header = T)
agg_soil_swat <- read.delim(paste(net_soil_dir, file_agg_soil_units,sep = '/'))
mukey_lu <- read.delim(paste(net_soil_dir, file_mukey_hrugrp_lu, sep = '/'))

hdrs <- c(
    "MUID", 
    "SNAM",                      
    'SAND1', 
    'SAND2', 
    'SAND3', 
    'SAND4',
    'SAND5',
    'CLAY1', 
    'CLAY2', 
    'CLAY3', 
    'CLAY4', 
    'CLAY5', 
    'SOL_BD1', 
    'SOL_BD2', 
    'SOL_BD3', 
    'SOL_BD4', 
    'SOL_BD5',
    "SOL_AWC1", 
    "SOL_AWC2", 
    "SOL_AWC3", 
    "SOL_AWC4", 
    "SOL_AWC5",
    "USLE_K1", 
    "USLE_K2", 
    "USLE_K3", 
    "USLE_K4", 
    "USLE_K5", 
    "SOL_K1",
    "SOL_K2",
    "SOL_K3",
    "SOL_K4",
    "SOL_K5")
soil_tbl <- subset(agg_mapunits, select = hdrs)
soil_tbl$hru_grp <- NA
for (grp in unique(mukey_lu$hru_grp)){
#     grp_mus <- subset(mukey_lu, hru_grp == grp, select = MUID)
    grp_mus <- mukey_lu$MUID[which(mukey_lu$hru_grp == grp)]
    grp_ind <- which(soil_tbl$MUID %in% grp_mus)
    soil_tbl[grp_ind,'hru_grp'] <- grp
}
soil_tbl <- melt(soil_tbl, 
              id.vars = c('hru_grp','SNAM', 'MUID'), 
              measure.vars = hdrs[!(hdrs %in% c('hru_grp','SNAM','MUID'))])

hz = str_extract(soil_tbl$variable, "[0-9]")
vrbl = str_extract(soil_tbl$variable, "([A-Z]|_)*")
soil_tbl$variable = vrbl
soil_tbl$horizon = hz

pdf("Soil_Groups.pdf",height=8, width = 16)
for (prp in unique(soil_tbl$variable)){
#     prp <- 'SAND1'
    d = soil_tbl[soil_tbl$variable == prp,]
    gp <- ggplot(d, aes(x=hru_grp, y=value, fill=horizon)) + 
        geom_boxplot() +
        ggtitle(paste(prp))
    plot(gp)
}
dev.off()
# 
# 
# data(airquality)
# 
# set.seed(2014) # set seed for reproducibility, (in case kMeans is variable)
# pdf('ScreePlots_9runs_MacQueen.pdf')
# par(mfrow=c(3,3))
# for (hsg in LETTERS[1:4]) {
#     for (r in 1:9){
#     #     hsg <- 'D'
#         ind = which(soil_tbl$HYDGRP == hsg & !(soil_tbl$SNAM %in% excld))
#         clus_d = agg_tbl[ind,]
#         # For each HSG, find clusters
#         clus_d_scld <- scale(clus_d)
#         wss <- (nrow(clus_d)-1)*sum(apply(clus_d_scld,2,var))
#         for (i in 2:15) {
#             try(wss[i] <- sum(kmeans(clus_d_scld, centers=i, iter.max = 1e6, algorithm='MacQueen')$withinss))
#         }
#         plot(1:15, wss, type="b", xlab="Number of Clusters",
#              ylab="Within groups sum of squares", 
#              main = paste('HSG:', hsg), sub = paste("Run no.", r))
#     }
# }
# dev.off()
# 
# # Model Based Clustering
# library(mclust)
# for (hsg in LETTERS[1:4]) {
# 	ind = which(soil_tbl$HYDGRP == hsg & !(soil_tbl$SNAM %in% excld))
# 	clus_d = agg_tbl[ind,]
# 	clus_d_scld <- scale(clus_d)
# 	fit <- Mclust(clus_d_scld, G=3)
# 	print(summary(fit))
# }
# 
# clus_d_scld <- scale(clus_d)
# # Determine number of clusters
# wss <- (nrow(clus_d)-1)*sum(apply(clus_d,2,var))
# for (i in 2:15) {
#     try(wss[i] <- sum(kmeans(clus_d, centers=i)$withinss))
# }
# plot(1:15, wss, type="b", xlab="Number of Clusters",
#      ylab="Within groups sum of squares")
# 
# Hydgrp A: optimal clusters = 5
# Hydgrp B: optimal clusters = 5
# Hydgrp C: optimal clusters = 6
# Hydgrp D: optimal clusters = 
# 
# 
# 
# 
# 
# pamTest <- pam(clus_d_scld, 5)
# 
# 
# area_table = merge(mupolygon@data,
# 	soil_tbl[,c("MUID", "hru_grp", "SNAM")],
# 	by.x = "MUKEY",
# 	by.y = "MUID",
# 	all.x = T)
# 
# agg_tbl = aggregate(Shape_Area ~ hru_grp, data=area_table, FUN=sum)
# with(agg_tbl, barplot(Shape_Area, names.arg=hru_grp))
# 
# # look at characteristics of groups
# 
# 
# write.dbf(soil_tbl, 'soil_tbl_take_a_peek.dbf')
# # taking a look at clusters
# pdf("Cluster_Characteristics_v2.pdf", height = 10, width = 14)
# par(mfrow=c(4,5))
# for (varbl in c('SAND1',"USLE_K1", "SOL_CBN1", 
# 				 "SOL_AWC1", "SOL_BD1", "SOL_K1")){
# #	 varbl <- 'SAND1'
# 	 for (hsg in LETTERS[1:4]){
# 	 #	 hsg <- 'A'
# 		 xlm <- range(soil_tbl[which(soil_tbl$HYDGRP == hsg),varbl])
# 		 hist(soil_tbl[which(soil_tbl$HYDGRP == hsg),varbl],
# 			  main = paste('All Hyd Group', hsg),
# 			  xlab = paste(varbl), xlim = xlm)
# 		 for (grp in seq(1,4)){
# 	 #		 grp <- 1
# 			 hsg_grp <- paste(hsg,grp,sep="") 
# 			 sbst <- subset(soil_tbl, hru_grp == hsg_grp)
# 			 hist(sbst[,varbl], main = paste(hsg_grp),
# 				  xlab = paste(varbl), xlim = xlm)
# 			 mtext(paste("Contains",nrow(sbst), "profiles"))
# 		 }
# 	 }
# }
# dev.off()
# 
# # for plotting as soil prof object
# slb <- dcast(grp_slab, top + bottom ~ variable)
# slb$prf <- 1
# depths(slb) <- prf ~ top + bottom
# plot(slb)	 
# # for plotting soil prop values with depth
# xyplot(top ~ value, groups = variable, data = grp_slab,
# 	 ylim=c(650, -5), type=c('l','g'), asp=1.5,
# 	 ylab='Depth (mm)', xlab='Soil Property Values',
# 	 auto.key=list(columns=4, lines=TRUE, points=FALSE),
# 	 panel=function(...) {
# 		 panel.xyplot(...)
# 		 panel.abline(h=grp_slab$top, lty=2, lwd=2)
# 	 })
