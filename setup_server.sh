#!/bin/bash 

# Define function first


function inputMapBoxkeyandInsertintosettings {
    read -p "To begin with the installation type in the mapbox key:" mbkey

    echo "You entered:"
    echo $mbkey

    read -p "If this is correct, enter "yes": " out

    if ! [ "$out" = "yes" ]
    then
        echo "You did not type in 'yes'. Exiting....Mapbox key not in yet. Please check documentation."
        exit 1
    fi
    
    
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    echo "Editing settings.py to put Mapbox key in that you entered above."

    # mbkey was entered above
    #sed -i 's/=""/="$mbkey"/g' ~/cloud_station_web/webgms/settings.py
    sed -i "s/=\"\"/=\"$mbkey\"/g" ~/cloud_station_web/webgms/settings.py
    #sed -i "s/=\"\"/=\"$var\"/g" your_file
}


function inputGoogleMapsKeyandSaveToEnv {
    read -p "To begin with the installation type in the google maps key:" gmkey

    echo "You entered:"
    echo $gmkey

    read -p "If this is correct, enter "yes": " out

    if ! [ "$out" = "yes" ]
    then
        echo "You did not type in 'yes'. Exiting....Google maps key not in yet. Please check documentation."
        exit 1
    fi
    
    
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    echo "Editing ~/cloud_station_web/.env to put google maps key in that you entered above."

    touch ~/cloud_station_web/.env
    echo GOOGLE_MAP_API_KEY=$gmkey>~/cloud_station_web/.env
}


# get mapbox API key from command line (easier long run)


# Check if an API key is provided as a command-line argument
if [ "$#" -eq 1 ]; then
    api_key="$1"
    echo "Using provided MB API key: $api_key"
else
    # If no API key is provided, prompt the user to enter one
    read -p "Enter your MB API key: " api_key
fi

# Now you can use the $api_key variable in your script
echo "API key: $api_key"

# Rest of your script goes here...

start_time="$(date -u +%s)"


echo "######### Setting up server #########"
echo "For Linux Ubuntu Server 22.04 LTS Web Services"


echo -e "\n1. Updating Ubuntu"
# Update package database
sudo apt-get update -y

# Configure needrestart to automatically restart services
# sudo sed -i 's/^#\$nrconf{restart}.*$/$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf

# Upgrade packages
sudo apt-get upgrade -y


echo -e "\n2. Installing NGINX and docker"
echo "Installing NGINX"
sudo apt-get --yes install nginx
echo "Configuring nginx.conf"
#curl http://checkip.amazonaws.com # our public IP address
sed -i "s/www\.example\.com/$(hostname -I | awk '{print $2}')/g" ~/cloud_station_deployment/nginx.conf
sudo usermod -a -G $USER www-data


# Temporary clone the dev branch
echo -e "\n3. Cloning CloudStation web app source code"
#git clone https://github.com/CloudStationTeam/cloud_station_web.git
git clone https://github.com/CloudStationTeam/cloud_station_web.git --branch dev --single-branch

# Checkout release if specified Temporary removed until dev branch committed to release.
#for arg in "$@"
#do
#    case $arg in
#        --tag=*)
#		TAG="${arg#*=}"
#		echo "Checkout out release $TAG"
#		cd ~/cloud_station_web
#       git checkout $TAG
#        cd ~
#        shift # Remove --cache= from processing
#        ;;
#        *)
#        shift # Remove generic argument from processing
#        ;;
#    esac
#done


echo -e "\n4. Setting up Python virtual environment"
sudo apt-get --yes install python3-venv
mkdir ~/ENV
python3 -m venv ~/ENV # Creates python virtual environment.
source ~/ENV/bin/activate # Activates python virtual environment.

# These dependencies are required for pymavlink
sudo apt-get --yes install libxml2-dev libxslt-dev python3-dev
sudo apt-get --yes install libffi-dev
sudo apt-get --yes install python3-lxml #Now install python3-lxml

# Install requirements from your requirements.txt file without using cache
pip3 install -r ~/cloud_station_web/requirements.txt --no-cache-dir

#echo "getting mapbox key"
#inputMapBoxkeyandInsertintosettings

echo "Editing settings.py to put Mapbox key in that you entered above."
sed -i "s/=\"\"/=\"$api_key\"/g" ~/cloud_station_web/webgms/settings.py

echo "Changing server IP to ALLOWED_HOSTS to everything in cloud_station_web/webgms/settings.py"
#sed -i 's/\[\]/\[\*\]/g' ~/cloud_station_web/webgms/settings.py
sed -i "s/\[\]/['*']/g" ~/cloud_station_web/webgms/settings.py
echo "Turning off debug mode in cloud_station_web/webgms/settings.py"
sed -i 's/DEBUG = True/DEBUG = False/g' ~/cloud_station_web/webgms/settings.py

# echo "getting google maps key"
# inputGoogleMapsKeyandSaveToEnv



# Command to add to the last line of bashrc
command_to_add="export PROMPT_COMMAND='history -a'"

# Append the command to the last line of ~/.bashrc
echo "$command_to_add" >> ~/.bashrc

# Reload the bashrc
source ~/.bashrc

echo "Command added to the last line of ~/.bashrc and bashrc reloaded."


echo "Finished setting up server!"
echo "now running bash ~/cloud_station_deployment/configure_web_server.sh "
bash ~/cloud_station_deployment/configure_web_server.sh

echo "Finished running configure_web_server server!"
end_time="$(date -u +%s)"

elapsed="$(($end_time-$start_time))"
echo "Total of $elapsed seconds elapsed for the entire process"


minutes=$((elapsed / 60))
seconds=$((elapsed % 60))
echo "Ellapsed time ${minutes} minutes ${seconds} seconds"





