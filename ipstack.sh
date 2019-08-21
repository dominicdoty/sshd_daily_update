#!/bin/bash
## Simple Curl Based Wrapper for ipstack.com

##ARGUMENT HANDLING
while getopts 'hai:' flag; do
    case "${flag}" in
        h) HELP='true' ;;
		i) IP="${OPTARG}" ;;
		a) INSTALL=true ;;
    esac
done


##HELP
if [ "$HELP" = 'true' ]; then
	echo "IPSTACK BASH WRAPPER - Quick bash wrapper to perform a curl of the ipstack.com API"
	echo "   -i : IP address arg, 'check' gives results for self"
	echo "   -a : Install the script (set API key and copy to /usr/local/bin)"
	exit 0
fi

## INSTALLATION
if [ "$INSTALL" = true ]; then
    echo "Installing Ipstack Script"

    ## Get ipstack API Key
    echo -n "Checking for ipstack.com API keyfile "
    if test -f ipstack_api.key ; then
        IPSTACK_APIKEY=$(cat ipstack_api.key)
        echo "[OK]"
    else
        echo "[MISSING]"
        read -p "Input your ipstack.com API Key: " IPSTACK_APIKEY
    fi

	sed -e "s/IPSTACK_APIKEY=\"NULL\"/IPSTACK_APIKEY=\"$IPSTACK_APIKEY\"/g" ipstack.sh > ipstack.tmp.sh
	sudo chmod u+x ipstack.tmp.sh


    ## Test ipstack API Key
    echo -n "Testing API key "
    RESPONSE=$(./ipstack.tmp.sh -i "check")
    if ! grep -qP "ip\":\"\d+" <<< "$RESPONSE"; then
        echo >&2 "[BAD] ipstack api key bad"
		rm ipstack.tmp.sh
        exit 1
    else
        echo "[OK]"
    fi


    ## Install ipstack
    echo -n "Copying ipstack.sh to /usr/local/bin "
    sudo mv ipstack.tmp.sh /usr/local/bin/ipstack || { echo >&2 "[BAD] copying failed"; exit 1; }
    echo "[OK]"

    echo -n "Setting permisions on ipstack.sh "
    sudo chown root:root /usr/local/bin/ipstack || { echo >&2 "[BAD] Failed to update script owner to root"; exit 1; }
    sudo chmod 755 /usr/local/bin/ipstack || { echo >&2 "[BAD] Failed to update permissions to 755"; exit 1; }
    echo "[OK]"

	exit 0
fi

## Static Variables
IPSTACK_URL="http://api.ipstack.com/"
IPSTACK_KEYPREFIX="?access_key="
IPSTACK_APIKEY="NULL"

## Request
if [ "$IP" = "" ]; then
	IP="check"
fi

if (! grep -qP "^([0-9\.]+)$" <<< $IP) && ( ! [ "$IP" = "check" ] ); then
    #not a legal IP (at least not made of numbers and periods)
    echo "Suspect illegal IP passed to ipstack_lookup, looking up own IP"
    IP="check"
fi

REQUEST="$IPSTACK_URL""$IP""$IPSTACK_KEYPREFIX""$IPSTACK_APIKEY"
RESPONSE=$(curl -s "$REQUEST")
echo "$RESPONSE"
