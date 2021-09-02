# ATMA-BUNTU
The UBUNTU varient that can hibernate to a USB/Harddrive and also has almost all packages ready to rn live sessions that are automatically backed up to an ext4 parition on the live USB itself.
See: https://docs.google.com/document/d/1KU4YJ9K5QS8isoYNjRoawy-thgZakF7aIsEqvMHDBLw/edit for details

Here is how you may use this scripts to create your own ATMA-BUNTU
1. Pull the Code to a suitable folder in your computer.
2. unzip th zip files to the same root folder.
3. Run the script mk-Atmabuntu.sh
4. It may ask you permissions to install and remove some files. Answer yes 
5. The process may take 2 to 3 hrs depending on the speed of your hardware.
6. The iso image will be created in a folder atmabuntu under /home.
7. It will also try to write the image to the ventoy USB folder (assuming it is attached to the USB port of your computer)
8. You can edit mkU3.sh script to remove or specify a different location to save the iso file.
Enjoy!
## Detailed instructions
1. The mk-Atmabuntu script is self explanatory and it takes input "Fresh" to create a fresh distribution iso image of ATMA-BUNTU. Running the script without "Fresh" as argument will add new featres to the existing folders - saves time when you want to ad new packages in addition to what is existing or to replace some with new ones. If no old folderes are found, it creats them.
2. The basic installation set up for the computer are done by the mkU1.sh and mkU11.sh scripts.
3. The iso file settings are done by mkU2.sh file that is copied to the root folder by the mkU1*.sh script.
4. The mkU1* script prompts for 3 possible versions of ATMABUNTU, It asks: "Please specify which version to install (tiny, executive, GIS):". Here tiny is not really tiny. It is the basic version that is about 2.5GB in size. The executive version is about 5Gb and has most of the needed packages. The GIS package has some GIS software in addition to the executive live image.
5. It is possible to alter what you want by editing packages_list.txt file in the Update folder for executive or the Gis_packages_list.txt file for the GIS version.
6. The tiny version do not install any of the additional packages except what are specified in mkU2.sh script itself. 
7.  To run mkU2.sh, the mk-Atmabuntu script takes you to the command prompt. Type mkU2.sh and press Enter key.
8. Towards the end of the kkU2.sh installation, the script prompts again. If you wish to apt install any new packages that you do not include in the pakages_list, you can do it directly here and type Exit followed by Enter key to clean up and come o the theird command prompt. Type exit here.
9. The script will now run mkU3.sh which creates the iso file. You can edit the last lines of this script to specify if you want the installation to be done at a location other than the default /home folder and the ventoy USB drive.
10. That's all! You are ready with your personal version of atmabuntu!
