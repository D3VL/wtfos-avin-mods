#!/system/bin/sh

echo "[avin-mods] start";

# goggle memory locations
memloc_map=0x1020f428
memloc_address=0x1020f42c
memloc_value=0x1020f430

map_main=0x21
map_vpp=0x42
map_csi=0x44

function writeToRegister {
    address=$1
    value=$2

    echo "[avin-mods] writing $value to register $address";

    busybox devmem $memloc_address 8 $address && 
    busybox devmem $memloc_value 8 $value
}

# Get the values from the config 
ENCODING_BIN=$(package-config getsaved avin-mods encoding)
ENCODING_BIN+="0100" # default bits from documentation

ENCODING_INT=$((2#$ENCODING_BIN))

echo "[avin-mods] setting encoding to $ENCODING_INT ($ENCODING_BIN)";

if [ $ENCODING_BIN != "00010100" ]; then
    # disable auto encoding detection
    # writeToRegister 0x07 0x00; <-- commented out because we can only send one command 

    # set the encoding
    writeToRegister 0x02 $ENCODING_INT;
else 
    # enable auto encoding detection
    # writeToRegister 0x07 0x01;  <-- commented out because we can only send one command 

    # set the encoding to auto
    writeToRegister 0x02 $ENCODING_INT;
fi

# VV commented out because we can only send one command, so encoding gets it VV
# Get the values from the config 
# DISABLE_FREE_RUN=$(package-config getsaved avin-mods disable-free-run)

# if [ $DISABLE_FREE_RUN == "true" ]; then    
#     echo "[avin-mods] disabling free run mode";
#     # disable free run mode
#     writeToRegister 0x0C 0x34;
# fi

echo "[avin-mods] completed!";

