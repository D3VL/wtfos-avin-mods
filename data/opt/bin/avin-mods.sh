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
        memloc_map=$(($memloc_map + 4))
        memloc_address=$(($memloc_address + 4))
        memloc_value=$(($memloc_value + 4))
    fi
done

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

    memloc_map=$(($memloc_map + 4))
    memloc_address=$(($memloc_address + 4))
    memloc_value=$(($memloc_value + 4))
}

# Get the values from the config 
ENCODING_BIN=$(package-config getsaved avin-mods encoding)
ENCODING_BIN+="0100" # default bits from documentation

[ "$ENCODING_BIN" = "PAL0100" ] && ENCODING_BIN="10000100"
[ "$ENCODING_BIN" = "NTSC0100" ] && ENCODING_BIN="01010100"
[ "$ENCODING_BIN" = "AUTO0100" ] && ENCODING_BIN="00010100"

ENCODING_INT=$((2#$ENCODING_BIN))

echo "[avin-mods] setting encoding to $ENCODING_INT ($ENCODING_BIN)";

if [ $ENCODING_BIN != "00010100" ]; then
    # disable auto encoding detection
    writeToRegister 0x21 0x07 0x00;

    # set the encoding
    writeToRegister 0x21 0x02 $ENCODING_INT;
else 
    # enable auto encoding detection
    writeToRegister 0x21 0x07 0x01;

    # set the encoding to auto
    writeToRegister 0x21 0x02 $ENCODING_INT;
fi


# Get the values from the config 
DISABLE_FREE_RUN=$(package-config getsaved avin-mods disable-free-run)

if [ $DISABLE_FREE_RUN == "true" ]; then    
    echo "[avin-mods] disabling free run mode";
    # disable free run mode
    writeToRegister 0x21 0x0C 0x34;
fi

echo "[avin-mods] completed!";

