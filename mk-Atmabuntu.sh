
if [ "$1" == "Fresh" ];  then
./mkU1.sh
else
./mkU11.sh

fi
./mkU3.sh
umount /media/nsp/Ventoy
echo "All done! Safe to remove drive"
