library(RODBC)
options(warn=2)
#project directories 

#CHANGE TO PROJECT DATABASE
prjDir = "C:/SWAT/Reservoirs_2"
insert_fert = TRUE

#DONT TOUCH
prjDb = paste(prjDir, "/", basename(prjDir), ".mdb", sep="")
swatDb = paste(prjDir, "SWAT2012.mdb", sep="/")
netDir = "T:/Projects/Wisconsin_River/Model_Inputs/SWAT_Inputs/LandCoverLandManagement"

#DONT TOUCH
crosswalk_file = paste(netDir, "Landuse_Lookup.csv", sep="/")

# Read in all necessary tables

crosswalk = read.csv(crosswalk_file)

con_updates = odbcConnectAccess(paste(netDir, "OpSchedules_fert.mdb", sep="/"))
opSched = sqlFetch(con_updates, "OpSchedules")
fert = sqlFetch(con_updates, "fert")
close(con_updates)

con_fert = odbcConnectAccess(swatDb)
fert_query = paste("INSERT INTO fert (IFNUM,FERTNM,FMINN,FMINP,FORGN,FORGP,FNH3N,",
    "BACTPDB,BACTLPDB,BACTKDDB,FERTNAME,MANURE) VALUES (55,'20-10-18',0.200,0.044,",
    "0.000,0.000,0.00,0,0,0,'Starter WRB',0);", sep="")
fert_row_count = sqlQuery(con_fert, "SELECT COUNT(OBJECTID) FROM fert;")[[1]]
if (fert_row_count < 55) {
    sqlQuery(con_fert, fert_query)
}
close(con_fert)

con_mgt1 = odbcConnectAccess(prjDb)
mgt1 = sqlFetch(con_mgt1, "mgt1")
close(con_mgt1)

con_mgt2 = odbcConnectAccess(prjDb)
sqlQuery(con_mgt2, "SELECT * INTO mgt2_backup FROM mgt2;")
sqlQuery(con_mgt2, "DROP TABLE mgt2")
sqlQuery(con_mgt2, "Select * Into mgt2 From mgt2_backup Where 1 = 2")
close(con_mgt2)

py_file = tempfile(fileext=".py")
write(paste("import arcpy; arcpy.Compact_management('", prjDb, "')", sep=""), py_file)

con_mgt2 = odbcConnectAccess(prjDb)

oidStart = 1
for (row in 1:nrow(mgt1)) {
    row_data = mgt1[row,]
    print(paste(as.character(row_data$SUBBASIN), as.character(row_data$HRU)))
    lu = as.character(row_data$LANDUSE)
    opCode = unique(as.character(crosswalk$KEY[crosswalk$LANDUSE == lu]))
    if (opCode =="800") {opCode = "HAY"}
    if (substr(opCode, 1, 1) == "3" & substr(opCode, 4, 4) == "c") {
        igro_query = paste("UPDATE mgt1 SET IGRO = 1, PLANT_ID = 52, NROT = 0 WHERE SUBBASIN = ",
            as.character(row_data$SUBBASIN),
            " AND HRU = ",
            as.character(row_data$HRU),
            ";",
            sep=""
        )
        sqlQuery(con_mgt2, igro_query)
    }
    operation = opSched[gsub(" " , "", as.character(opSched$SID)) == opCode,]
    operation$SUBBASIN = as.character(row_data$SUBBASIN)
    operation$HRU = as.character(row_data$HRU)
    operation$LANDUSE = as.character(row_data$LANDUSE)
    operation$SOIL = as.character(row_data$SOIL)
    operation$SLOPE_CD = as.character(row_data$SLOPE_CD)
    formatTempFile = tempfile()
    write.csv(operation[,2:ncol(operation)], formatTempFile, row.names=F, quote=T)
    colNames = readLines(formatTempFile, 1)
    colNames = gsub("\"", "", colNames)
    for (opRow in 1:nrow(operation)) {
        values = readLines(formatTempFile, opRow + 1)[opRow + 1]
        values = gsub("\"", "'", values)
        values = gsub("NA", "NULL", values)
        insertQuery = paste(
            "INSERT INTO mgt2 (",
            colNames,
            ") VALUES (",
            values,
            ");",
            sep=""
        )
        sqlQuery(con_mgt2, insertQuery)
    }
    if (row %% 500 == 0) {
        close(con_mgt2)
        print("Compacting database. Please wait...")
        system(paste("C:\\Python27\\ArcGIS10.1\\python.exe", py_file))
        con_mgt2 = odbcConnectAccess(prjDb) 
    }
}
