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

# Get the values from the config 
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

setMemToDefaults;

echo "[avin-mods] completed!";

