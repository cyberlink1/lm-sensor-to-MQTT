# lm-sensor-to-MQTT
A script to read the hardware sensors output on a Linux machine create MQTT entries for them

This script uses the command line tool sensors which is part of the lm-sensors package on Linux. It collects all sensor data and posts it to an MQTT server as <hostname>/<Adapter>/<Sensor>
  
You will need the following perl modules to make it work

String::Util
Sys::Hostname
Net::MQTT::Simple::Auth
Getopt::Std

You can set defaults at the top of the file or specify the entries on the command line. If you want to check it and see what topics it will use you can run it with the -o option. This will output the topics and data without updating the MQTT server. 

You can also use it to check a remote server over ssh. You will have to put a password-less ssh key on the remote server for the given account and make sure that lm-sensors is installed. I did this because my HA system is a KVM and it can not directly talk to the host it runs on.

I have it running every 5 min and updating my MQTT server so my HA system can react to changes in the hardware and notify me.

NOTE: This will not work on a VM as there are no hardware sensors on a VM!
NOTE 2: The Raspberry pi has 1 sensor for temperature. It has had issues with sensors in the past so your mileage may vary. 
