# Merges, prunes and cleans data as an exercise for DSJH Getting & Cleaning Data. 
# Author: NJBlume; Date: 20150321 - Version 1

setwd("~/..")
setwd("Desktop/LIFE/Courses/Coursera/DSJH/3_Getting and Cleaning Data/A")

# obtain & load dependencies
if (!require("stringr")){
    install.packages("stringr", dependencies=TRUE)
}

library("stringr")

if (!require("reshape2")){
    install.packages("reshape", dependencies=TRUE)
}

library("reshape2")

if (!require("plyr")){
    install.packages("reshape", dependencies=TRUE)
}

library("plyr")

if(!file.exists("dataset.zip")){
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip' ,destfile="dataset.zip")
}


unzip("dataset.zip")

if(!file.exists("UCI HAR Dataset")){
    stop("Failed to get the data. Program is stopping.")
}

setwd("UCI HAR Dataset")

#1 Merges the training and the test sets to create one data set.

doc <- read.table("features.txt", header=FALSE)
variableNames <- doc$V2
train <- read.table("train/X_train.txt", header=FALSE, col.names=variableNames)
test <- read.table("test/X_test.txt", header=FALSE, col.names=variableNames)
mergedData <- rbind(train, test)

#2 Extracts only the measurements on the mean and standard deviation for each measurement. 

subsetData <- mergedData[, grep("*\\.(mean|std)\\..*", names(mergedData), value=T)]
rm(mergedData)

# Prepare additional columnar information

variableNames <- c("subject")
subjectTrain <- read.table("train/subject_train.txt", header=FALSE, col.names=variableNames)
subjectTest <- read.table("test/subject_test.txt", header=FALSE, col.names=variableNames)
mergedSubjects <- rbind(subjectTrain, subjectTest)

variableNames <- c("activity")
activityTrain <- read.table("train/y_train.txt", header=FALSE, col.names=variableNames)
activityTest <- read.table("test/y_test.txt", header=FALSE, col.names=variableNames)
mergedActivities <- rbind(activityTrain, activityTest)

#3 Uses descriptive activity names to name the activities in the data set

variableNames <- read.table("activity_labels.txt", header=FALSE, col.names=c("activity", "activityName"))
relabeledActivities <- merge(mergedActivities, variableNames, by="activity", sort=F)
relabeledActivities <- relabeledActivities[, 2]

# Merge the columns into one data frame

df <- cbind(mergedSubjects, relabeledActivities, subsetData)

#4 Appropriately labels the data set with descriptive variable names. 

colnames(df) <- tolower(str_replace_all(colnames(df), "([A-Z]{1})", ".\\1")) #separate capitalized strings by ".", then cast everything to lower case
colnames(df) <- str_replace_all(colnames(df), "[\\.]+", ".") #replace successive "." with single "."
colnames(df) <- str_replace_all(colnames(df), "[\\.]+$", "") #remove dot at the end of the string
colnames(df) <- str_replace_all(colnames(df), "relabeled.activities", "activity") 

#5 From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

meltedData <- melt(df, id=c("subject","activity")) #make the data long
summarizedData <- ddply(meltedData, c("subject", "activity", "variable"), summarise, mean = mean(value)) #compute mean by 3 factors
tidyMeans <- dcast(summarizedData, subject + activity ~ variable, value.var="mean") #make mean data wide

# saves the data to the same folder as the script

setwd("~/..")
setwd("Desktop/LIFE/Courses/Coursera/DSJH/3_Getting and Cleaning Data/A")
#write.table(df, file="tidy.txt", quote=FALSE, row.name=FALSE)
write.table(tidyMeans, file="tidyMeans.txt", quote=FALSE, row.name=FALSE)