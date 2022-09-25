#!/system/bin/sh

echo "[avin-mods] start";

# v2 goggle memory locations
memloc_map=0x1020f428
memloc_address=0x1020f42c
memloc_value=0x1020f430

# TODO: add check if V1 goggles, and set the memory locations accordingly

map_main=0x21
map_vpp=0x42
map_csi=0x44

HAS_SET=0;

function setMemToDefaults {
    echo "[avin-mods] resetting memory values to default";
    busybox devmem $memloc_map 8 $map_main &&
    busybox devmem $memloc_address 8 0x0F &&
    busybox devmem $memloc_value 8 0x00
}

function writeToRegister {
    address=$1
    value=$2

    busybox devmem $memloc_address 8 $address &&
    busybox devmem $memloc_value 8 $value
}

while [ true ] do

    IS_AVMODE=`busybox devmem 0x10e2af14 8`

    if [ $IS_AVMODE != '0x01' ]; then # we're not in av mode

        # if we're not in Av mode and we set the addresses before, reset them
        if [ $HAS_SET == '1' ]; then
            setMemToDefaults;
            HAS_SET=0;
        fi

        sleep 10; # wait 10 seconds and check again
        return
    fi

    # we are in AV mode
    
    # if we've already the options, wait 10 seconds and check again
    if [ $HAS_SET -eq 1 ]; then
        sleep 10;
        return
    fi

    # we are in AV mode, get the values from the config 
    ENCODING_BIN=$(package-config getsaved wtfos-avin-mods encoding)
    ENCODING_BIN+="0100" # default bits from documentation

    ENCODING_INT=$((2#$ENCODING_BIN))

    echo "[avin-mods] setting encoding to $ENCODING_INT ($ENCODING_BIN)";

    if [ $ENCODING_BIN != "00010100" ]; then
        # disable auto encoding detection
        writeToRegister 0x07 0x00;

        # set the encoding
        writeToRegister 0x02 $ENCODING_INT;
    else 
        # enable auto encoding detection
        writeToRegister 0x07 0x01;

        # set the encoding to auto
        writeToRegister 0x02 $ENCODING_INT;
    fi


    DISABLE_FREE_RUN=$(package-config getsaved wtfos-avin-mods disable-free-run)

    if [ $DISABLE_FREE_RUN == "true" ]; then    
        echo "[avin-mods] disabling free run mode";
        # disable free run mode
        writeToRegister 0x0C 0x34;
    fi

    HAS_SET=1;

    echo "[avin-mods] mods applied";

    # sleep for 10s and start the loop again
    sleep 10;

done


