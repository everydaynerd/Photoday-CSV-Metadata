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
# Don't use spaces in your folder names if possible. The photoPath might break if using spaces. 


# Install Prerequsites:
# brew install csvkit
# brew install jq
# brew install exiftool

# ________________________________________________

# Path to Raw files (With trailing slash)
photoPath='../sample-photos/'

csvFile='sample'
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

read -r -p "Enter the year/season: " year

printf "\t${LIGHTGREEN}You entered the following data:"
printf "\t\t${LIGHTGREEN}YEAR: ${LIGHTBLUE}${year}${COLOR_RESET}\n"

read -r -p "Continue? [y/N] " yearresponse
if [[ "$yearresponse" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
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
      if [ -z "$personGrade" ]; then
        echo "\$personGrade is NULL"
        personGrade=0
    else
        echo "\$personGrade is NOT NULL"
    fi
  

    accessCode=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."Access Code"')
    lastName=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."Last Name"')
    firstName=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."First Name"')
    fullName="$firstName $lastName"
    orgname=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."School"')
    orgname=$(echo $orgname | sed 's/ //g')
    activity=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."Sport Type"')
    activity=$(echo $activity | sed 's/ //g')
    team=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."Team"')
    league=$(echo $jsonData | jq -r --arg i "$i" '.[$i|tonumber]."League"')
    
    if [ -z "$(echo $jsonData | jq -r .[$i].League)" ]; then
        echo "League doesn't exist in CSV"
    else
        echo "League does exist"
        leagueName=$(echo $jsonData | jq -r .[$i].League)
    fi

    if [ -z "$(echo $jsonData | jq -r .[$i].Team)" ]; then
        echo "Team doesn't exist in CSV"
    else
        echo "Team does exist"
        teamName=$(echo $jsonData | jq -r .[$i].Team)
    fi
    
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
        
        # # If League exists, write it.
        if [ ! -z "$leagueName" ]; then
            exiftool -overwrite_original -Subject+="${leagueName}" ${photoPath}${rawFile}${fileType}
            exiftool -overwrite_original -Caption="${leagueName}" ${photoPath}${rawFile}${fileType}
        fi

        # If Team exists, write it.
        if [ ! -z "$teamName" ]; then
            exiftool -overwrite_original -Subject+="${teamName}" ${photoPath}${rawFile}${fileType}
        fi

        # ------- Write Job Identifier -------
        # Format for writing: {Year/Season}_{School/Organization}_{Sport/Activity}_{Team}_{League} - Example: 20-21_WHHS_Basketball_Varsity_Boys

        # If League defined (girls/boys) write it i the Job Identifier. If not, then leave it out.
        if [ ! -z "$league" ]; then #leage variable DOES exist
            exiftool -overwrite_original -xmp:transmissionreference=${year}_${orgname}_${activity}_${team}_${league} ${photoPath}${rawFile}${fileType}
        else # leage variable DOESN'T exist.
            exiftool -overwrite_original -xmp:transmissionreference=${year}_${orgname}_${activity}_${team} ${photoPath}${rawFile}${fileType}
        fi
        # ---------------------------------
        
        #Write Gallery Code in User Comment
        exiftool -overwrite_original -UserComment=PhotoDayGallery:${accessCode} ${photoPath}${rawFile}${fileType}



        #Verify Keyword tag(s) are written:
        exiftool -Subject   ${photoPath}${rawFile}${fileType}
        exiftool -Caption   ${photoPath}${rawFile}${fileType}
    done
done
# Cleanup
rm ./${csvFile}.json


printf "\t${LIGHTBLUE}OK all finished!${COLOR_RESET}\n\n"
printf "\t${LIGHTBLUE}Now open Lightroom, select the files that have been updated, choose menu option Metadata, Read Metadata from Files${COLOR_RESET}\n\n"
# Enjoy life, and find the joy!
