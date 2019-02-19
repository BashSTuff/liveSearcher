#! /bin/bash
# Coded by BashSTuff 
# Ver1.0
##############################################################################################
###                         BASH IPVv4 live host mapper		                           ###
##############################################################################################
# 
# Script uses ICMP via native ping cmd to map live hosts to IPv4 addr.  
# No results if ping command is blocked, nonexistent, or ICMP is being dropped at EGRESS/INGRESS.
# ATM, no scanning of CIDRs lower than /8  or greater than /30      
#
# Do one of the following:
#
#			subnet search 	
# 1) bash liveSearcher.sh 192.168.1.0/24
#
#			range search   	
# 2) bash liveSearcher.sh 192.168.1.0-254
# 3) bash liveSearcher.sh 192.168.1.0-15.254
# 3) bash liveSearcher.sh 192.168.1.0-253.15.254
#
#			single search	
# 5) bash liveSearcher.sh 192.168.1.0
##


IPR=`echo $1 |cut -d'-' -f1`
RANGE=`echo $1 |cut -d'-' -f2`
D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})  
CIDR=`echo $1 |cut -d'/' -f2`
IP=`echo $1 |cut -d'/' -f1`


function range_sweep() {
	if [[ $RANGE =~ ^[0-9]{1,3}$ &&  $RANGE -gt $(echo $IPR|cut -d'.' -f4) ]]; then                                
		echo "Scanning " $IPR-$RANGE					
		IP=`echo $IPR|cut -d'.' -f1,2,3`
		sleep 1

		for c in `seq $(echo $IPR|cut -d'.' -f4) $RANGE`; do 
			ping -c1 $IP.$c 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4|cut -d":" -f1 &

		done
		sleep 1		
		echo "Live host search:  Complete"

	elif [[ $RANGE =~ ^[0-9]{1,3}\.[0-9]{1,3}$ && $(echo $RANGE|cut -d'.' -f1) -gt $(echo $IPR|cut -d'.' -f3) ]]; then                                
		echo "Scanning " $IPR-$RANGE					
		IP=`echo $IPR|cut -d'.' -f1,2`
		STOPRANGE=$(($(echo $RANGE|cut -d'.' -f2)+1)) # uses +1 to stop at user entered LAST host.
		sleep 1

		for b in `seq $(echo $IPR|cut -d'.' -f3) $(echo $RANGE|cut -d'.' -f1)`; do 
			for c in `seq 0 255`; do
				if [ $b.$c == $(echo $RANGE|cut -d'.' -f1).$STOPRANGE ]; then 
					sleep 1
					echo "Live host search:  Complete"
					exit 1

				else 
					ping -c1 $IP.$b.$c 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4|cut -d":" -f1 &

				fi

			done

		done

	elif [[ $RANGE =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ && $(echo $RANGE|cut -d'.' -f1) -gt $(echo $IPR|cut -d'.' -f2) ]]; then                                
		echo "Scanning " $IPR-$RANGE					
		IP=`echo $IPR|cut -d'.' -f1`
		STOPRANGE=$(($(echo $RANGE|cut -d'.' -f3)+1))
		sleep 1

		for a in `seq $(echo $IPR|cut -d'.' -f2) $(echo $RANGE|cut -d'.' -f1)`; do 
			for b in `seq 0 255`; do
				for c in `seq 0 255`; do
					if [ $a.$b.$c == $(echo $RANGE|cut -d'.' -f1).$(echo $RANGE|cut -d'.' -f2).$STOPRANGE ]; then # Stops at user supplied LAST host.
						sleep 1
						echo "Live host search:  Complete"
						exit 1

					else 
						ping -c1 $IP.$a.$b.$c 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4|cut -d":" -f1 &

					fi

				done

			done

		done

	else
		echo -e "\nerror in user input."	

	fi
}


function subnet_sweep() {
	if [ $CIDR -eq 30 -o $CIDR -eq 22 -o $CIDR -eq 14 ]; then
		STOPNET=3
		NETMASK=${D2B[252]} # convert mask into binary

	elif [ $CIDR -eq 29 -o $CIDR -eq 21 -o $CIDR -eq 13 ]; then
		STOPNET=7
		NETMASK=${D2B[248]}

	elif [ $CIDR -eq 28 -o $CIDR -eq 20 -o $CIDR -eq 12 ]; then
		STOPNET=15
		NETMASK=${D2B[240]}

	elif [ $CIDR -eq 27 -o $CIDR -eq 19 -o $CIDR -eq 11 ]; then
		STOPNET=31
		NETMASK=${D2B[224]}

	elif [ $CIDR -eq 26 -o $CIDR -eq 18 -o $CIDR -eq 10 ]; then
		STOPNET=63
		NETMASK=${D2B[192]}

	elif [ $CIDR -eq 25 -o $CIDR -eq 17 -o $CIDR -eq 9 ]; then
		STOPNET=127
		NETMASK=${D2B[128]}

	elif [ $CIDR -eq 24 -o $CIDR -eq 16 -o $CIDR -eq 8 ]; then
		STOPNET=255		
		NETMASK=${D2B[0]}

	elif [ $CIDR -eq 23 -o $CIDR -eq 15 ]; then
		STOPNET=3
		NETMASK=${D2B[254]}

	fi

	if [ $CIDR -le 30 -a $CIDR -ge 24 ]; then 
		echo "Scanning " $IP/$CIDR					
		# calculate subnet here
		IPNUMBER=${D2B["${c=`echo $IP |cut -d'.' -f4`}"]} # The convert the subnet oct of $IP into binary
		IP=`echo $IP|cut -d'.' -f1,2,3`
		STARTNET=$(( 2#$IPNUMBER & 2#$NETMASK ))  # AND'ing done here
		sleep 1

		for c in `seq $(($STARTNET+1)) $(($STARTNET+$STOPNET-1))`; do # ping subnet minus netID and broadcast 
			ping -c1 $IP.$c 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4|cut -d":" -f1 &

		done
		sleep 1		
		echo "Live host search:  Complete"

	elif [ $CIDR -le 23 -a $CIDR -ge 16 ]; then
		echo "Scanning " $IP/$CIDR					
		IPNUMBER=${D2B["${b=`echo $IP |cut -d'.' -f3`}"]} 
		IP=`echo $IP|cut -d'.' -f1,2`
		STARTNET=$(( 2#$IPNUMBER & 2#$NETMASK ))
		sleep 1

		for b in `seq $(($STARTNET)) $(($STARTNET+$STOPNET))`; do 
			for c in `seq 0 255`; do
				if [ $IP.$b.$c == $IP.$(($STARTNET+$STOPNET)).255 ]; then # prevent pinging broadcast
					sleep 1
					echo "Live host search:  Complete"

				else
					ping -c1 $IP.$b.$c 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4|cut -d":" -f1 &

				fi

			done

		done


	elif [ $CIDR -le 15 -a $CIDR -ge 8 ]; then
		echo "Scanning " $IP/$CIDR					
		IPNUMBER=${D2B["${a=`echo $IP |cut -d'.' -f2`}"]} 
		IP=`echo $IP|cut -d'.' -f1`
		STARTNET=$(( 2#$IPNUMBER & 2#$NETMASK ))
		sleep 1

		for a in `seq $STARTNET $(($STARTNET+$STOPNET))`; do 
			for b in `seq 0 255`; do
				for c in `seq 0 255`; do
					if [ $IP.$a.$b.$c == $IP.$(($STARTNET+$STOPNET)).255.255 ]; then
						sleep 1						
						echo "Live host search:  Complete"

					else
						ping -c1 $IP.$a.$b.$c 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4|cut -d":" -f1 &

					fi

				done

			done

		done

	else
	echo -e "\nerror somehwere in the subnet_sweep function"		

	fi
}


### Main ###
if [ $# -ne 1 ]; then     
    echo -e "Enter a single IPv4 addr, IPv4 range, or IPv4 addr with cidr.\n"
	echo "cmd example, bash liveSearcher.sh 172.16.0.0/16"
	echo "cmd example, bash liveSearcher.sh 192.18.1.0-1.254"    
	echo "cmd example, bash liveSearcher.sh 10.10.10.100"    

elif [ $1 == "--help" -o  $1 == "-h" ]; then
    echo -e "Enter a single IPv4 addr, IPv4 range, or IPv4 addr with cidr.\n"
	echo "cmd example, bash liveSearcher.sh 10.0.0.0/8"
	echo "cmd example, bash liveSearcher.sh 172.18.113.0-25.0.254"
	echo "cmd example, bash liveSearcher.sh 192.168.1.200"

# single IPv4 ping
elif [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	echo -e "Scanning " $1 '\n'
	ping -c1 $1 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4|cut -d":" -f1 
	echo -e "\nLive host search:  Complete"
									
# range IPv4 sweep
elif [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}$ ]] || 
	 [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}$ ]] || 
	 [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then 
	 range_sweep

# subnet IPv4 sweep
elif [[ $CIDR =~ [0-9]{1,2} ]] && 
	 [ $CIDR -le 30 -a $CIDR -ge 8 ] && 
	 [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	 subnet_sweep

else
	echo -e "\nerror in user input"

fi


