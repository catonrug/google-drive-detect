#!/bin/sh

#this code is tested un fresh 2015-02-09-raspbian-jessie-lite Raspberry Pi image
#by default this script should be located in two subdirecotries under the home

#sudo apt-get update -y && sudo apt-get upgrade -y
#sudo apt-get install git -y
#mkdir -p /home/pi/detect && cd /home/pi/detect
#git clone https://github.com/catonrug/google-drive-detect.git && cd google-drive-detect && chmod +x check.sh && ./check.sh

#check if script is located in /home direcotry
pwd | grep "^/home/" > /dev/null
if [ $? -ne 0 ]; then
  echo script must be located in /home direcotry
  return
fi

#it is highly recommended to place this directory in another directory
deep=$(pwd | sed "s/\//\n/g" | grep -v "^$" | wc -l)
if [ $deep -lt 4 ]; then
  echo please place this script in deeper directory
  return
fi

#set application name based on directory name
#this will be used for future temp directory, database name, google upload config, archiving
appname=$(pwd | sed "s/^.*\///g")

#set temp directory in variable based on application name
tmp=$(echo ../tmp/$appname)

#create temp directory
if [ ! -d "$tmp" ]; then
  mkdir -p "$tmp"
fi

#check if database directory has prepared 
if [ ! -d "../db" ]; then
  mkdir -p "../db"
fi

#set database variable
db=$(echo ../db/$appname.db)

#if database file do not exist then create one
if [ ! -f "$db" ]; then
  touch "$db"
fi

#check if google drive config directory has been made
#if the config file exists then use it to upload file in google drive
#if no config file is in the directory there no upload will happen
if [ ! -d "../gd" ]; then
  mkdir -p "../gd"
fi

if [ -f ~/uploader_credentials.txt ]; then
sed "s/folder = test/folder = `echo $appname`/" ../uploader.cfg > ../gd/$appname.cfg
else
echo google upload will not be used cause ~/uploader_credentials.txt do not exist
fi

name=$(echo "Google Drive")

#set url
enterpriseurl=$(echo "https://dl.google.com/drive/gsync_enterprise.msi")

#get all info about url
wget -S --spider -o $tmp/output.log $enterpriseurl

grep -A99 "^Resolving" $tmp/output.log | grep "HTTP.*200 OK"
if [ $? -eq 0 ]; then
#if file request retrieve http code 200 this means OK

grep -A99 "^Resolving" $tmp/output.log | grep "Content-Length" 
if [ $? -eq 0 ]; then
#if there is such thing as Content-Length

grep -A99 "^Resolving" $tmp/output.log | grep "Last-Modified" 
if [ $? -eq 0 ]; then
#if there is such thing as Last-Modified

#cut out last modified
enterpriselastmodified=$(grep -A99 "^Resolving" $tmp/output.log | grep "Last-Modified" | sed "s/^.*: //")

enterprisefilename=$(echo $enterpriseurl | sed "s/^.*\///g")

grep "$enterprisefilename $enterpriselastmodified" $db > /dev/null
if [ $? -ne 0 ]; then

echo new version detected!
echo

echo Downloading $enterprisefilename
wget $enterpriseurl -O $tmp/$enterprisefilename -q
echo

echo extracting installer..
7z x $tmp/$enterprisefilename -y -o$tmp > /dev/null
echo

echo searching exact version number
version=$(pestr $tmp/googledrivesync.exe | grep -m1 -A1 "ProductVersion" | grep -v "ProductVersion")

echo $version | grep "^[0-9]\+[\., ]\+[0-9]\+[\., ]\+[0-9]\+[\., ]\+[0-9]\+"
if [ $? -eq 0 ]; then
echo

echo creating md5 checksum of file..
enterprisemd5=$(md5sum $tmp/$enterprisefilename | sed "s/\s.*//g")
echo

echo creating sha1 checksum of file..
enterprisesha1=$(sha1sum $tmp/$enterprisefilename | sed "s/\s.*//g")
echo

#this version should contain direct link to it
url=$(echo "https://dl.google.com/drive/$version/gsync.msi")

#get all info about url
wget -S --spider -o $tmp/output.log $url

grep -A99 "^Resolving" $tmp/output.log | grep "HTTP.*200 OK"
if [ $? -eq 0 ]; then
#if file request retrieve http code 200 this means OK

grep -A99 "^Resolving" $tmp/output.log | grep "Content-Length" 
if [ $? -eq 0 ]; then
#if there is such thing as Content-Length

grep -A99 "^Resolving" $tmp/output.log | grep "Last-Modified" 
if [ $? -eq 0 ]; then
#if there is such thing as Last-Modified

#cut out last modified
lastmodified=$(grep -A99 "^Resolving" $tmp/output.log | grep "Last-Modified" | sed "s/^.*: //")

#set filename
filename=$(echo $url | sed "s/^.*\///g")

grep "$filename $lastmodified" $db > /dev/null
if [ $? -ne 0 ]; then

echo Downloading $filename
wget $url -O $tmp/$filename -q
echo

echo creating md5 checksum of file..
md5=$(md5sum $tmp/$filename | sed "s/\s.*//g")
echo

echo creating sha1 checksum of file..
sha1=$(sha1sum $tmp/$filename | sed "s/\s.*//g")
echo

#lets put all signs about this file into the database
echo "$enterprisefilename $enterpriselastmodified">> $db
echo "$version">> $db
echo "$enterprisemd5">> $db
echo "$enterprisesha1">> $db
echo >> $db
echo "$filename $lastmodified">> $db
echo "$url">> $db
echo "$version">> $db
echo "$md5">> $db
echo "$sha1">> $db
echo >> $db

#create unique filename for google upload
newfilename=$(echo $enterprisefilename | sed "s/\.msi/_`echo $version`\.msi/")
mv $tmp/$enterprisefilename $tmp/$newfilename

#if google drive config exists then upload and delete file:
if [ -f "../gd/$appname.cfg" ]
then
echo Uploading $newfilename to Google Drive..
echo Make sure you have created \"$appname\" direcotry inside it!
../uploader.py "../gd/$appname.cfg" "$tmp/$newfilename"
echo
fi

#lets send emails to all people in "posting" file
emails=$(cat ../posting | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "$name $version msi" "$url 
$md5
$sha1

https://2e6b3d70b345cdbc4db6289569c3331791ee1634.googledrive.com/host/0B_3uBwg3RcdVQVN1WFIxX09xd2M/$newfilename 
$enterprisemd5
$enterprisesha1"
} done
echo



else
#if file already in database
echo $filename already in database						
fi

else
#if link do not include Last-Modified
echo Last-Modified field is missing from output.log
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "To Do List" "Last-Modified field is missing from output.log: 
$url"
} done
echo 
echo
fi

else
#if link do not include Content-Length
echo Content-Length field is missing from output.log
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "To Do List" "Content-Length field is missing from output.log: 
$url"
} done
echo 
echo
fi

else
#if http statis code is not 200 ok
echo Did not receive good http status code
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "To Do List" "the following link do not retrieve good http status code: 
$url "
} done
echo 
echo
fi

else
#version do not match version pattern
echo version do not match version pattern
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "To Do List" "Version do not match version pattern: 
$url "
} done
fi

else
#if file already in database
echo $enterprisefilename already in database						
fi

else
#if link do not include Last-Modified
echo Last-Modified field is missing from output.log
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "To Do List" "Last-Modified field is missing from output.log: 
$enterpriseurl "
} done
echo 
echo
fi

else
#if link do not include Content-Length
echo Content-Length field is missing from output.log
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "To Do List" "Content-Length field is missing from output.log: 
$enterpriseurl "
} done
echo 
echo
fi

else
#if http statis code is not 200 ok
echo Did not receive good http status code
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "To Do List" "the following link do not retrieve good http status code: 
$enterpriseurl "
} done
echo 
echo
fi

#clean and remove whole temp direcotry
rm $tmp -rf > /dev/null
