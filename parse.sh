#!/bin/bash

# ________________________________________________
# Background:
# Using PhotoDay.io is awesome, and I love the facial recognition feature. 
# This feature allows me to simply take a reference photo of each subject in the PhotoDay.io capture app, instead of using QR codes.
# Once I upload all the photos to the PRIVATE gallery in photoday, the facial recognition process matches each photo with the person.
# After the photos are matched, a CSV file can be downloaded with a list of file names assiciated with the person data.

# Problem:
# I used Lightroom titles and keywords for managing photos. 
# I wanted a way for the people data from PhotoDay.io csv export to live in the metadata of Lightroom too.

# Solution:
# Using `exiftool` I'm able to write XMP tags that Lightroom reads.

# Usage:
# Download the CSV from PhotoDay, and place it in the same directory as this script file. I recomend creating a dedicated directory.
# Find the location of your raw images (or jpg - not judging!), and copy the path.
# Set the `photoPath` variable below to your directory path (including the trailing slash) eg: /Volumes/Storage/Lightroom/2020/06-20/
# Set the `csvFile` variable below to the name of your csv file (excluding the file extension) eg: girls-golf - not girls-golf.csv
# If needed, set the `photoExt` variable to the photos file extension have. I convert mine on import to Lightroom to dng, so that's the default.

# Install Prerequsites:
# brew install csvkit
# brew install jq
# brew install exiftool

# ________________________________________________

# Path to Raw files
photoPath='/Volumes/Storage/Lightroom/2020/2020-09-24/'

csvFile='jlm-jv-tennis'
# csvFile name without extension

photoExt='dng'
photoExt2='tiff'

# No need to change anything below this line - unless you just want to experiment!
# ________________________________________________

# Just because colors are fun... 
export LIGHTBLUE='\e[1;34m'
export LIGHTGREEN='\e[1;32m'
export LIGHTCYAN='\e[1;36m'
export LIGHTRED='\e[1;31m'
export LIGHTMAGENTA='\e[95m'
export YELLOW='\e[1;33m'
export COLOR_RESET="\e[0m"

printf "\t${LIGHTRED}Make sure to SAVE all Metadata in Lightroom before running.${COLOR_RESET}\n"

read -r -p "Continue? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    printf "\t${LIGHTBLUE}OK great.${COLOR_RESET}\n"

else
    printf "\t${LIGHTRED}OK Bye!${COLOR_RESET}\n"
    exit 1
fi


if [[ -d ${photoPath} ]]; then
    printf "\t${LIGHTGREEN}Directory ${photoPath} exists. Let's continue.${COLOR_RESET}\n"
else
    printf "\t${LIGHTRED}Error: Directory ${photoPath} does NOT exist. Quiting.${COLOR_RESET}\n"
    exit 1
fi



# Verify CSV file exists
if [[ -f ./${csvFile}.csv ]]; then
    printf "\t${LIGHTGREEN}CSV file ${csvFile}.csv exists. Let's continue.${COLOR_RESET}\n"
else
    printf "\t${LIGHTRED}Error: File ${csvFile}.csv does NOT exist. Quiting.${COLOR_RESET}\n"
    exit 1
fi

csvjson $csvFile.csv > $csvFile.json

jsonData=$(cat ${csvFile}.json)
# echo $jsonData | jq -r .

# Get length of JSON object (number of people in data)
jsonLength=$(echo $jsonData | jq '. | length')
# echo $jsonLength
printf "\t${LIGHTMAGENTA}Found ${jsonLength} people in the CSV Data.${COLOR_RESET}\n"


for (( i = 0; i < $jsonLength; i++ )); do

    personGrade=$(echo $jsonData | jq -r .[$i].Grade)

    # echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."Last Name"'
    lastName=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."Last Name"')
    # echo $lastName
    # echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."First Name"'
    firstName=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."First Name"')
    # echo $firstName
    fullName="$firstName $lastName"
    # echo $fullName
    photoList=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."Photo Filenames"')
    printf "\t${LIGHTCYAN}Updating Metadata for ${YELLOW}${fullName}.${COLOR_RESET}\n"

    IFS=', ' read -r -a array <<< "$photoList"
    for element in "${array[@]}"; do
        rawFile=$(sed 's/.\{3\}$//' <<< "$element")
        echo ${photoPath}${rawFile}${photoExt}

        # Verify photo file exists
        if [[ -f ${photoPath}${rawFile}${photoExt} ]]; then
            printf "\t${LIGHTGREEN} file ${rawFile}dng exists. Let's continue.${COLOR_RESET}\n"
            fileType=dng
        elif [[ -f ${photoPath}${rawFile}${photoExt1} ]]; then
            printf "\t${LIGHTGREEN} file ${rawFile}tif exists. Let's continue.${COLOR_RESET}\n"
            fileType=tif
        elif [[ -f ${photoPath}${rawFile}jpg ]]; then
            printf "\t${LIGHTGREEN} file ${rawFile}jpg exists. Let's continue.${COLOR_RESET}\n"
            fileType=jpg
        else
            printf "\t${LIGHTGREEN} file not found.${COLOR_RESET}\n"
        fi

        # Write the fullName to the XMP Title Metadata field (Personal preference)
        exiftool -overwrite_original -Title="$fullName" ${photoPath}${rawFile}${fileType}
        #Verify tag was written:
        exiftool -Title ${photoPath}${rawFile}${fileType}
        
        # Write the fullName as a Keyword so when exporting to PhotoDay it will tag the person's name
        exiftool -overwrite_original -Subject+="$fullName" ${photoPath}${rawFile}${fileType}

        # If the person is a senior, tag that as well
        if [ $personGrade == "12" ]; then
            exiftool -overwrite_original -Subject+="senior" ${photoPath}${rawFile}${fileType}
        fi
        
        #Verify Keyword tag(s) are written:
        exiftool -Subject   ${photoPath}${rawFile}${fileType}
    done
done
# Cleanup
rm ./${csvFile}.json

printf "\t${LIGHTBLUE}OK all finished!${COLOR_RESET}\n\n"
printf "\t${LIGHTBLUE}Now open Lightroom, select the files that have been updated, choose menu option Metadata, Read Metadata from Files${COLOR_RESET}\n\n"
# Enjoy life, and find the joy!
