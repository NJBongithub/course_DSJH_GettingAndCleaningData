# CodeBook

## Original Data

The data is a subset of accelerometer readings from the Samsung Galaxy S smartphone of several volunteers in a study by Anguita et al. (2012). The data is available at http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

### Study Design
 
As described on http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones):

The experiments have been carried out with a group of 30 volunteers within an age bracket of 19-48 years. Each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist. Using its embedded accelerometer and gyroscope, we captured 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz. The experiments have been video-recorded to label the data manually. The obtained dataset has been randomly partitioned into two sets, where 70% of the volunteers was selected for generating the training data and 30% the test data. 

The sensor signals (accelerometer and gyroscope) were pre-processed by applying noise filters and then sampled in fixed-width sliding windows of 2.56 sec and 50% overlap (128 readings/window). The sensor acceleration signal, which has gravitational and body motion components, was separated using a Butterworth low-pass filter into body acceleration and gravity. The gravitational force is assumed to have only low frequency components, therefore a filter with 0.3 Hz cutoff frequency was used. From each window, a vector of features was obtained by calculating variables from the time and frequency domain. 

For each record in the dataset it is provided: 
- Triaxial acceleration from the accelerometer (total acceleration) and the estimated body acceleration. 
- Triaxial Angular velocity from the gyroscope. 
- A 561-feature vector with time and frequency domain variables. 
- Its activity label. 
- An identifier of the subject who carried out the experiment.

For further reference: Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge L. Reyes-Ortiz. (Dec 2012.) Human Activity Recognition on Smartphones using a Multiclass Hardware-Friendly Support Vector Machine. International Workshop of Ambient Assisted Living (IWAAL 2012). Vitoria-Gasteiz, Spain.

## Environment Set-Up

Libraries are loaded.

```{r}
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
```

## Data Acquisition

The script downloads and unzips a data folder from a UCI website (https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip).

The data folder is called "data UCI HAR" and contains several files. Certain files contain training data and others contain test data. Furthermore, certain files contain variable labels, others contain subject identifiers, and others contain measurements. 

```{r}
if(!file.exists("dataset.zip")){
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip' ,destfile="dataset.zip")
}

unzip("dataset.zip")

if(!file.exists("UCI HAR Dataset")){
    stop("Failed to get the data. Program is stopping.")
}

setwd("UCI HAR Dataset")
```

## Data Transformation

### Consolidation of measurement data files
- Files features.txt, train/X_train.txt, and test/X_test.txt are loaded as data tables. 
- The features file contains english-language terms that describe each column in the X_ tables. 
- The X_ files contain measurements for different subjects and activities. 
- The X_ tables are combined with rbind(). The resulting data file has 10299 observations. 
- The script assigns the terms from the feature file to the column names of the data file.

```{r}
doc <- read.table("features.txt", header=FALSE)
variableNames <- doc$V2
train <- read.table("train/X_train.txt", header=FALSE, col.names=variableNames)
test <- read.table("test/X_test.txt", header=FALSE, col.names=variableNames)
mergedData <- rbind(train, test)
```

### Filtering of measurement data

Only mean and standard deviation values are kept. Other columns are dropped. 

```{r}
subsetData <- mergedData[, grep("*\\.(mean|std)\\..*", names(mergedData), value=T)]
```

### Other data are prepared

The subject files train\subject_train.txt and test\subject_test.txt are loaded as are the activity files train\y_train.txt and test\y_test.txt. 

Training and test files of the same type are combined with rbind(). 

```{r}
variableNames <- c("subject")
subjectTrain <- read.table("train/subject_train.txt", header=FALSE, col.names=variableNames)
subjectTest <- read.table("test/subject_test.txt", header=FALSE, col.names=variableNames)
mergedSubjects <- rbind(subjectTrain, subjectTest)

variableNames <- c("activity")
activityTrain <- read.table("train/y_train.txt", header=FALSE, col.names=variableNames)
activityTest <- read.table("test/y_test.txt", header=FALSE, col.names=variableNames)
mergedActivities <- rbind(activityTrain, activityTest)
```

### Use of Descriptive language for activity labels

Until now, activity labels were numbered from 1 to 6. The file activity_labels.txt has English language descriptions for each number. 
Now the script replaces these numbers in subsetData with their respective descriptive labels. 

```{r}
variableNames <- read.table("activity_labels.txt", header=FALSE, col.names=c("activity", "activityName"))
relabeledActivities <- merge(mergedActivities, variableNames, by="activity", sort=F)
relabeledActivities <- relabeledActivities[, 2]
```

### Further consolidation

The files that contain subject ids, those that contain activity descriptions and those that contain performance measurements are now combined with cbind().

```{r}
df <- cbind(mergedSubjects, relabeledActivities, subsetData)
```

### Improvement to variable names.

The variable names are simplified using regular expressions. For instance fBodyAccJerk.mean...Z. becomes f.body.acc.jerk.mean.z. The variables are listed below.

```{r}
colnames(df) <- tolower(str_replace_all(colnames(df), "([A-Z]{1})", ".\\1")) #separate capitalized strings by ".", then cast everything to lower case
colnames(df) <- str_replace_all(colnames(df), "[\\.]+", ".") #replace successive "." with single "."
colnames(df) <- str_replace_all(colnames(df), "[\\.]+$", "") #remove dot at the end of the string
colnames(df) <- str_replace_all(colnames(df), "relabeled.activities", "activity") 
```

### A second, independent tidy data set with the average of each variable for each activity and each subject.

The tidy file is then reduced by computing mean scores BY subject AND activity for each measurement device.

Specifically:
- Using the melt function from the reshape package, the file is melted so that there are as many rows as combinations of subject, activity and measurement device.
- The ddplyr function from the plyr package is used to compute the mean score for each unique combination of subject, activity and measurement device.
- The resulting summary file is then recast using dcast from the reshape2 package so that each measurement occupies its own column.

```{r}
meltedData <- melt(df, id=c("subject","activity")) #make the data long
summarizedData <- ddply(meltedData, c("subject", "activity", "variable"), summarise, mean = mean(value)) #compute mean by 3 factors
tidyMeans <- dcast(summarizedData, subject + activity ~ variable, value.var="mean") #make mean data wide
```

### File export

The recast summary file is saved as tidyMeans.txt alongside the script.

```{r}
setwd("~/..")
setwd("Desktop/LIFE/Courses/Coursera/DSJH/3_Getting and Cleaning Data/A")
write.table(tidyMeans, file="tidyMeans.txt", quote=FALSE, row.name=FALSE)
```

## Variables

The following is a table representing the variables of the tidy dataset. They are provided as they appear in the dataset. Variable subject is the participant anonymous code from the original experiment. It is an integer number ranging from 0 to 30. Variable activity is a categorical variable of the activity performed by the participants. Its value is one from the set {LAYING, SITTING, STANDING, WALKING, WALKING_DOWNSTAIRS, WALKING_UPSTAIRS}.`

All the other variables (ID 3 to 68) are the average of each original variable (see the third column) for each activity and each subject. Their value is numeric (float). It can be negative or positive.

|ID	|Name	|Original Name|
|----|-------|-------------|
|1	|subject	|N/A|
|2	|activity	|N/A|
|3	|t.body.acc.mean.x	|tBodyAcc-mean(x)|
|4	|t.body.acc.mean.y	|tBodyAcc-mean(y)|
|5	|t.body.acc.mean.z	|tBodyAcc-mean(z)|
|6	|t.body.acc.std.x	|tBodyAcc-std(x)|
|7	|t.body.acc.std.y	|tBodyAcc-std(y)|
|8	|t.body.acc.std.z	|tBodyAcc-std(z)|
|9	|t.gravity.acc.mean.x	|tGravityAcc-mean(x)|
|10	|t.gravity.acc.mean.y	|tGravityAcc-mean(y)|
|11	|t.gravity.acc.mean.z	|tGravityAcc-mean(z)|
|12	|t.gravity.acc.std.x	|tGravityAcc-std(x)|
|13	|t.gravity.acc.std.y	|tGravityAcc-std(y)|
|14	|t.gravity.acc.std.z	|tGravityAcc-std(z)|
|15	|t.body.acc.jerk.mean.x	|tBodyAccJerk-mean(x)|
|16	|t.body.acc.jerk.mean.y	|tBodyAccJerk-mean(y)|
|17	|t.body.acc.jerk.mean.z	|tBodyAccJerk-mean(z)|
|18	|t.body.acc.jerk.std.x	|tBodyAccJerk-std(x)|
|19	|t.body.acc.jerk.std.y	|tBodyAccJerk-std(y)|
|20	|t.body.acc.jerk.std.z	|tBodyAccJerk-std(z)|
|21	|t.body.gyro.mean.x	|tBodyGyro-mean(x)|
|22	|t.body.gyro.mean.y	|tBodyGyro-mean(y)|
|23	|t.body.gyro.mean.z	|tBodyGyro-mean(z)|
|24	|t.body.gyro.std.x	|tBodyGyro-std(x)|
|25	|t.body.gyro.std.y	|tBodyGyro-std(y)|
|26	|t.body.gyro.std.z	|tBodyGyro-std(z)|
|27	|t.body.gyro.jerk.mean.x	|tBodyGyroJerk-mean(x)|
|28	|t.body.gyro.jerk.mean.y	|tBodyGyroJerk-mean(y)|
|29	|t.body.gyro.jerk.mean.z	|tBodyGyroJerk-mean(z)|
|30	|t.body.gyro.jerk.std.x	|tBodyGyroJerk-std(x)|
|31	|t.body.gyro.jerk.std.y	|tBodyGyroJerk-std(y)|
|32	|t.body.gyro.jerk.std.z	|tBodyGyroJerk-std(z)|
|33	|t.body.acc.mag.mean	|tBodyAccMag-mean|
|34	|t.body.acc.mag.std	|tBodyAccMag-std|
|35	|t.gravity.acc.mag.mean	|tGravityAccMag-mean|
|36	|t.gravity.acc.mag.std	|tGravityAccMag-std|
|37	|t.body.acc.jerk.mag.mean	|tBodyAccJerkMag-mean|
|38	|t.body.acc.jerk.mag.std	|tBodyAccJerkMag-std|
|39	|t.body.gyro.mag.mean	|tBodyGyroMag-mean|
|40	|t.body.gyro.mag.std	|tBodyGyroMag-std|
|41	|t.body.gyro.jerk.mag.mean	|tBodyGyroJerkMag-mean|
|42	|t.body.gyro.jerk.mag.std	|tBodyGyroJerkMag-std|
|43	|f.body.acc.mean.x	|fBodyAcc-mean(x)|
|44	|f.body.acc.mean.y	|fBodyAcc-mean(y)|
|45	|f.body.acc.mean.z	|fBodyAcc-mean(z)|
|46	|f.body.acc.std.x	|fBodyAcc-std(x)|
|47	|f.body.acc.std.y	|fBodyAcc-std(y)|
|48	|f.body.acc.std.z	|fBodyAcc-std(z)|
|49	|f.body.acc.jerk.mean.x	|fBodyAccJerk-mean(x)|
|50	|f.body.acc.jerk.mean.y	|fBodyAccJerk-mean(y)|
|51	|f.body.acc.jerk.mean.z	|fBodyAccJerk-mean(z)|
|52	|f.body.acc.jerk.std.x	|fBodyAccJerk-std(x)|
|53	|f.body.acc.jerk.std.y	|fBodyAccJerk-std(y)|
|54	|f.body.acc.jerk.std.z	|fBodyAccJerk-std(z)|
|55	|f.body.gyro.mean.x	|fBodyGyro-mean(x)|
|56	|f.body.gyro.mean.y	|fBodyGyro-mean(y)|
|57	|f.body.gyro.mean.z	|fBodyGyro-mean(z)|
|58	|f.body.gyro.std.x	|fBodyGyro-std(x)|
|59	|f.body.gyro.std.y	|fBodyGyro-std(y)|
|60	|f.body.gyro.std.z	|fBodyGyro-std(z)|
|61	|f.body.acc.mag.mean	|fBodyAccMag-mean|
|62	|f.body.acc.mag.std	|fBodyAccMag-std|
|63	|f.body.body.acc.jerk.mag.mean	|fBodyBodyAccJerkMag-mean|
|64	|f.body.body.acc.jerk.mag.std	|fBodyBodyAccJerkMag-std|
|65	|f.body.body.gyro.mag.mean	|fBodyBodyGyroMag-mean|
|66	|f.body.body.gyro.mag.std	|fBodyBodyGyroMag-std|
|67	|f.body.body.gyro.jerk.mag.mean	|fBodyBodyGyroJerkMag-mean|
|68	|f.body.body.gyro.jerk.mag.std	|fBodyBodyGyroJerkMag-std|

The features variables generally follow the following naming convention

{f|t}.{body|gravity}.{acc|gyro}.{mag|mean|std}

where

t is time, f is the frequency, body and gravity are reference frames, acc is the accelerometer, gyro is the gyroscope, mag is the euclidean magnitude, mean is the average value, and std is the standard deviation. Jerk, where present, is the jerk signal, as opposed to smooth signal (everything else)