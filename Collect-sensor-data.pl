#!/bin/perl
###############################################################
#                     LM_Sensors output to MQTT               #
#                               V1.0                          #
#                             By Cyberlink1                   #
###############################################################
#
#
#
use String::Util 'trim';
use Sys::Hostname;
use Net::MQTT::Simple::Auth;
use Getopt::Std;
use strict vars;

#
# Setting global defaults
#
our %args;
our $OFFLINE = 0;
our $MQTT_Server = "none";
our $MQTT_Port = "1883";
our $MQTT_User = "Username";
our $MQTT_Password = "Password";
our $host = hostname;
our $adapter = "unknown";
our $mqtt;
our $Remote_Host = "none";
our $Remote_Login = "none";
our @TEST = "";

#
# Parsing command line options
#

getopts('?hom:p:u:s:r:l:', \%args) or usage();

sub usage {
    print "\nlm Sensors to MQTT\n";
    print "V1.0\n\n";
    print "Help\n\n";
    print " -h or -? output this help txt\n";
    print " -o Offline mode. Print to screen instead of MQTT server\n";
    print " -m<Servr Address> Set the MQTT Server Addres\n";
    print " -p<port> Set the MQTT Server port\n";
    print " -u<login> Set the User ID to use when connecting to MQTT\n";
    print " -s<password> Set the User password to use when connecting to MQTT\n";
    print " -r<remote host> sets the remote system to exicute on\n";
    print " -l<remote host login> sets the login account for the remote host\n\n";

    exit;
    }

if ($args{h} or $args{'?'}) {
      usage();
     }



if ($args{o}) {
    $OFFLINE=1;
   }

if ($args{m}) {
    $MQTT_Server = $args{m};
    }

if ($args{u}) {
    $MQTT_User = $args{u};
    }

if ($args{s}) {
   $MQTT_Password = $args{s};
   }

if ($args{p}) {
   $MQTT_Port = $args{p};
   }

if ($args{r}) {
   $Remote_Host = $args{r};
   $host = $args{r};
   }

if ($args{l}) {
   $Remote_Login = $args{l};
   }

#
# connecting to mqtt server
#
if ($OFFLINE == 1 || $MQTT_Server eq "none") {
        print "Offline Mode\n";
        }else{
        if ($MQTT_User) {
        $mqtt = Net::MQTT::Simple::Auth->new($MQTT_Server.":".$MQTT_Port, $MQTT_User, $MQTT_Password );
         }else{
        $mqtt = Net::MQTT::Simple::Auth->new($MQTT_Server.":".$MQTT_Port);
         }
        }
#
# Lets pull the sensor data
#  Collect data on the local machine with 'sensors | tr -s " " | grep :'
#  We can pull remote data provided we have a registered ssh key.
#  we do that with the command
#      ssh -l <login> <server-name> 'sensors | tr -s " " | grep :'
# We run sensors and remove the multiple blank spaces and make them
# a single space.
# We then grep for just the lines containing a :
#

if ($Remote_Host ne "none" and $Remote_Login ne "none") {
  @TEST = `ssh -l $Remote_Login $Remote_Host 'sensors | tr -s " " | grep :'`;
  }else{
  @TEST = `/bin/sensors | /bin/tr -s \" \" | /bin/grep :`;
  }
  our $size = @TEST;


#
#
# Lets parse the sensor data
#
# if the item is "Adapter" then we use it to set the Adapter in the topic
# We remove °C, +, -, W, V, and RPM from the responces as we are just interested in the numbers.
#
our $count = 0;

while ( $count < $size ) {
        my ($item, $reading) = split(/:/, @TEST[$count]);
        $reading = trim($reading);
        $reading =~ s/\s*//gs;
        $item =~ s/\+//gs;
        if ( $item  eq "Adapter" ) {
                $adapter = $reading;
                }else{
                $reading =~ tr/°/ /;
                $reading =~ tr/C/ /;
                $reading =~ tr/+/ /;
                $reading =~ tr/RPM/ /;
                $reading =~ tr/W/ /;
                $reading =~ tr/V/ /;
                $reading =~ tr/-/ /;
        $reading =~ s/\s*//gs;
        our @reading = split(/\(/, $reading);
          if ($OFFLINE == 1 || $MQTT_Server eq "none") {
             print "Publishing \"$host/$adapter/$item\" with \"@reading[0]\"\n";
            }else{
             $mqtt->publish("$host/$adapter/$item" => "@reading[0]") || die("Unable to connect to MQTT server");
             # We sleep to slow down the sending of data. If it is too fast
             # MQTT does not catch it all.
             sleep(1);
            }
           }
        $count++;
}
