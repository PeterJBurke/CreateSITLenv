# CreateSITLenv
Script to create SITL setup on Linux.

To run: 
 ```
sudo apt-get install curl -y;
curl https://raw.githubusercontent.com/PeterJBurke/CreateSITLenv/main/setup.sh > ~/setup.sh;
chmod 777 ~/setup.sh;
bash ~/setup.sh;
```

Once installed here is an example command to run SITL:
 ```
cd ~/ardupilot/ArduCopter;  sim_vehicle.py --console --map --osd --out=udp:35.94.121.200:14550 --custom-location=33.64586111,-117.84275,25,0
 ```

The first time you might have to run this:
 ```
. ~/.profile
 ```
