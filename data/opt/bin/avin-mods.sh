#!/system/bin/sh

echo "[avin-mods] start";

# goggle memory locations
memloc_map=270595112 # 0x1020f428
memloc_address=270595116 # 0x1020f42c
memloc_value=270595120 # 0x1020f430

map_main=0x21
map_vpp=0x42
map_csi=0x44

found_end_of_table=0

while [ $found_end_of_table -eq 0 ]; do
    if [ $(busybox devmem $memloc_map 8) == "0x00" ]; then
        found_end_of_table=1
        echo "[avin-mods] found end of table at $memloc_map";
    else
        memloc_map=$(($memloc_map + 12))
        memloc_address=$(($memloc_address + 12))
        memloc_value=$(($memloc_value + 12))
    fi
done

# Used for dumping back the values
function scanDown {
    tmemloc_map=270595112 # 0x1020f428
    tmemloc_address=270595116 # 0x1020f42c
    tmemloc_value=270595120 # 0x1020f430
    tfound_end_of_table=0
    while [ $tfound_end_of_table -eq 0 ]; do
        echo "$tmemloc_map -> $(busybox devmem $tmemloc_map 8) $(busybox devmem $tmemloc_address 8) $(busybox devmem $tmemloc_value 8)";
        tmemloc_map=$(($tmemloc_map + 12))
        tmemloc_address=$(($tmemloc_address + 12))
        tmemloc_value=$(($tmemloc_value + 12))
        if [ $(busybox devmem $tmemloc_map 8) == "0x00" ]; then
            tfound_end_of_table=1
        fi
    done
}

function writeToRegister {
    map=$1
    address=$2
    value=$3

    echo "[avin-mods] writing $value to address $address on map $map";
    echo "[avin-mods] memloc_map: $memloc_map";
    echo "[avin-mods] memloc_address: $memloc_address";
    echo "[avin-mods] memloc_value: $memloc_value";

    busybox devmem $memloc_map 8 $map && 
    busybox devmem $memloc_address 8 $address && 
    busybox devmem $memloc_value 8 $value

    # if the write was successful, and we're not at the end of the table, move the pointers
    if [ $map != "0x00" ]; then
        memloc_map=$(($memloc_map + 12))
        memloc_address=$(($memloc_address + 12))
        memloc_value=$(($memloc_value + 12))
    fi
}

function backgroundPalLoop {

    echo "[avin-mods] Waiting for avin to be enabled";

    # wait for avin to be enabled
    while [ $(busybox devmem 0x10e2af14 8) == "0x00" ]; do
        busybox sleep 20;
    done

    echo "[avin-mods] avin enabled, disabling screen resize";
    busybox devmem 0xfffc10fb 8 0x00

    # wait for avin to be disabled
    while [ $(busybox devmem 0x10e2af14 8) == "0x01" ]; do
        busybox sleep 5;
    done

    echo "[avin-mods] avin disabled, restarting check loop";

    backgroundPalLoop;

}

ENCODING=$(package-config getsaved avin-mods encoding)

if [ "$ENCODING" == "PAL" ]; then 
    # loop and wait for avin to be enabled

    echo "[avin-mods] PAL selected";
    
    # start waiting for avin to be enabled in the background
    backgroundPalLoop &

elif [ "$ENCODING" == "NTSC" ]; then
    writeToRegister 0x21 0x07 0x00; # disable auto encoding
fi

# Get the values from the config 
ENCODINGADV_BIN=$(package-config getsaved avin-mods encoding-advanced)

if [ "$ENCODINGADV_BIN" != "OFF" ]; then
    # disable auto encoding detection
    writeToRegister 0x21 0x07 0x00;

    ENCODINGADV_BIN+="0100" # default bits from documentation
    ENCODINGADV_INT=$((2#$ENCODINGADV_BIN))

    echo "[avin-mods] setting encoding to $ENCODINGADV_INT ($ENCODINGADV_BIN)";

    # set the encoding
    writeToRegister 0x21 0x02 $ENCODINGADV_INT;
fi

# Get the values from the config 
DISABLE_FREE_RUN=$(package-config getsaved avin-mods disable-free-run)

if [ "$DISABLE_FREE_RUN" == "true" ]; then    
    echo "[avin-mods] disabling free run mode";
    # disable free run mode
    writeToRegister 0x21 0x0C 0x00;
fi

# Write a 0x00 to the end of the table to make sure the table is terminated
writeToRegister 0x00 0x00 0x00;

echo "[avin-mods] completed!";

