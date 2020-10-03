# Photoday.io CSV Export Metadata parser

## Background:

Using PhotoDay.io is awesome, and I love the facial recognition feature. 
This feature allows me to simply take a reference photo of each subject in the PhotoDay.io capture app, instead of using QR codes.
Once I upload all the photos to the PRIVATE gallery in photoday, the facial recognition process matches each photo with the person.
After the photos are matched, a CSV file can be downloaded with a list of file names assiciated with the person data.

## Problem

I used Lightroom titles and keywords for managing photos. 
I wanted a way for the people data from PhotoDay.io csv export to live in the metadata of Lightroom too.

## Solution

Using `exiftool` I'm able to write XMP tags that Lightroom reads.

## Usage

- Download the CSV from PhotoDay, and place it in the same directory as this script file. I recomend creating a dedicated directory.
- Find the location of your raw images (or jpg - not judging!), and copy the path.
- Set the `photoPath` variable below to your directory path (including the trailing slash) eg: /Volumes/Storage/Lightroom/2020/06-20/
- Set the `csvFile` variable below to the name of your csv file (excluding the file extension) eg: girls-golf - not girls-golf.csv

- If needed, set the `photoExt` variable to the photos file extension have. I convert mine on import to Lightroom to dng, so that's the default.

## Sample Data

Images in the sample-photos directory are AI Generated photos from https://generated.photos/

Names and phone numbers in the sample.csv are generated from https://www.fakenamegenerator.com/

Email addresses in the sample.csv uses Mailinator.com for fake, yet usable email addresses.