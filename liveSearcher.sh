#! /usr/bin/env bash
# Coded by BashSTuff 
# Ver1.5
##############################################################################################
###                         BASH IPv4 live host mapper		                           ###
##############################################################################################
# 
# Script uses ICMP via native ping cmd to map live hosts to IPv4 addr.  
# No results if ping command is blocked, nonexistent, or ICMP is being dropped at EGRESS/INGRESS.
# ATM, no scanning of CIDRs lower than /8  or greater than /30
# Some ping results may display out of order per the naute of sending out and waiting for ICMP packets
#
# Do one of the following:
#
#			subnet search 	
# 1) bash liveSearcher.sh 192.168.1.1/24
#
#			range search   	
# 2) bash liveSearcher.sh 192.168.1.1-254
# 3) bash liveSearcher.sh 192.168.1.1-15.254
# 3) bash liveSearcher.sh 192.168.1.1-253.15.254
#
#			single search	
# 5) bash liveSearcher.sh 192.168.1.1
##


IPR=`echo $1 |cut -d'-' -f1`
RANGE=`echo $1 |cut -d'-' -f2`
D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
CIDR=`echo $1 |cut -d'/' -f2`
IP=`echo $1 |cut -d'/' -f1`
IFS='.' read -a IPCHECK <<< $IP
IFS='.' read -a IPRCHECK <<< $IPR
IFS='.' read -a RANGECHECK <<< $RANGE
RANGELENGTH=`echo $RANGE|tr -cd '.'|wc -c`

function range_sweep() {
	IFS='.' read -r A B C D <<< $IPR #break individual octets into separate variables. The IP addr
	
	echo "Started at: `date`" && echo "Scanning IP4 range: " $IPR-$RANGE	
	case $RANGELENGTH in
		0)
			for z in `seq $D $RANGE`; do
				ping -c1 $A.$B.$C.$z 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 &

			done

		;;
		1)
			for z in `seq $D 255`; do
				ping -c1 $A.$B.$C.$z 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 &

			done
			for y in `seq $(($(echo $C) + 1 )) ${RANGECHECK[0]}`; do
				for z in `seq 0 255`; do
					ping -w4 -c1 $A.$B.$y.$z 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 &

					if [ $y.$z == ${RANGECHECK[0]}.${RANGECHECK[1]} ]; then
						break
					fi

				done			
				
			done
		;;
		2)
			for y in `seq $C 255`; do
				for z in `seq $D 255`; do
					ping -w4 -c1 $A.$B.$y.$z 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 &

				done

			done
			for x in `seq $(($(echo $B) + 1 )) ${RANGECHECK[0]}`; do
				for y in `seq 0 255`; do
					for z in `seq 0 255`; do
						ping -w5 -c1 $A.$x.$y.$z 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 &

						if [ $x.$y.$z == ${RANGECHECK[0]}.${RANGECHECK[1]}.${RANGECHECK[2]} ]; then					
							break
						fi

					done
				if [ $x.$y.$z == ${RANGECHECK[0]}.${RANGECHECK[1]}.${RANGECHECK[2]} ]; then # 2nd break needed here to break out of nested loops
					break 
				fi

				done 

			done
		;;
	esac
	echo "Stopped at: `date`"
	sleep 1 # added sleep here because sometimes ping results come back AFTER script's print statements
	echo "Live host search:  Complete"
	exit 0

}


function subnet_sweep() {
	IFS='.' read -r A B C D <<< $IP
	
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
	
	echo "Started at: `date`" && echo "Scanning IP4 subnet: " $IP/$CIDR
	if [ $CIDR -le 30 -a $CIDR -ge 24 ]; then 	
		# calculate subnet here
		IPNUMBER=${D2B["$D"]} # Convert the subnet oct of $IP into binary
		STARTNET=$(( 2#$IPNUMBER & 2#$NETMASK ))  # AND'ing done here

		for z in `seq $(($STARTNET + 1)) $(($STARTNET + $STOPNET - 1))`; do # ping subnet minus netID and broadcast 
			ping -c1 $A.$B.$C.$z 2>/dev/null |egrep -i "bytes from " |cut -d" " -f4,6 &

		done

	elif [ $CIDR -le 23 -a $CIDR -ge 16 ]; then		
		IPNUMBER=${D2B["$C"]} 
		STARTNET=$(( 2#$IPNUMBER & 2#$NETMASK ))

		for y in `seq $(($STARTNET)) $(($STARTNET + $STOPNET))`; do 
			for z in `seq 0 255`; do
				if [ $A.$B.$y.$z == $A.$B.$(($STARTNET + $STOPNET)).255 ]; then # prevent pinging broadcast
					break
				fi
				ping -w4 -c1 $A.$B.$y.$z 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 &

			done

		done


	elif [ $CIDR -le 15 -a $CIDR -ge 8 ]; then		
		IPNUMBER=${D2B["$B"]} 
		STARTNET=$(( 2#$IPNUMBER & 2#$NETMASK ))

		for x in `seq $STARTNET $(($STARTNET + $STOPNET))`; do 
			for y in `seq 0 255`; do
				for z in `seq 0 255`; do
					if [ $A.$x.$y.$z == $A.$(($STARTNET + $STOPNET)).255.255 ]; then
						break

					else						
						ping -w5 -c1 $A.$x.$y.$z 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 &

					fi

				done
				if [ $A.$x.$y.$z == $A.$(($STARTNET + $STOPNET)).255.255 ]; then # 2nd break needed here to break out of nested loops
						break
				fi

			done

		done

	else
	echo -e "\nerror somehwere in the subnet_sweep function"
	exit 1

	fi
	echo "Stopped at: `date`"
	sleep 1 # added sleep here because sometimes ping results come back AFTER script's print statements
	echo "Live host search:  Complete"
	exit 0
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
	ping -c1 $1 2>/dev/null|egrep -i "bytes from " |cut -d" " -f4,6 
	echo -e "\nLive host search:  Complete"
									
# range IPv4 sweep
elif [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || 
	 [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}$ ]] ||
	 [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}$ ]] && 
	 [[ $RANGELENGTH -eq 0 && ${RANGECHECK[0]} -gt ${IPRCHECK[3]} ]] || 
	 [[ $RANGELENGTH -eq 1 && ${RANGECHECK[0]} -gt ${IPRCHECK[2]} ]] || 
	 [[ $RANGELENGTH -eq 2 && ${RANGECHECK[0]} -gt ${IPRCHECK[1]} ]] &&
	 [[ ${RANGECHECK[0]} -le 255 && ${RANGECHECK[1]} -le 255 && ${RANGECHECK[2]} -le 255 ]] &&
	 [[ ${IPRCHECK[0]} -le 255 && ${IPRCHECK[1]} -le 255 && ${IPRCHECK[2]} -le 255 && ${IPRCHECK[3]} -le 255 ]]; then
	 range_sweep

# subnet IPv4 sweep
elif [[ $CIDR =~ [0-9]{1,2} ]] && 
	 [ $CIDR -le 30 -a $CIDR -ge 8 ] && 
	 [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] &&
	 [[ ${IPCHECK[0]} -le 255 && ${IPCHECK[1]} -le 255 && ${IPCHECK[2]} -le 255 && ${IPCHECK[3]} -le 255 ]]; then
	 subnet_sweep

else
	echo -e "\nerror in user input"
	exit 1
fi

