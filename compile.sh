#!/bin/bash
LUCI_DIR="configs/luci"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Compile OpenWrt
compile_openwrt() {
    make download -j$(nproc)
    make -j$(nproc) V=s || make -j4 V=s
    rm -rf packages

    if ls "$OUTPUT_DIR"/* | grep -q 'openwrt'; then
        echo "status=success" >> $GITHUB_OUTPUT
    fi
}

# Rename the compiled firmware with the configuration file name appended
firmware_rename() {
    # Get all files in bin/targets/*/* that contain 'openwrt' in their name
    firmware_files=$(ls bin/targets/*/* | grep 'openwrt')
    for firmware_file in $firmware_files; do
        firmware_name="$OUTPUT_DIR/[ Lite ]${firmware_file}"
        mv "$firmware_file" "$firmware_name"
    done
}

# Init config file
init_config(){
    echo "🚀 Loading model profiles "
    cat $CONFIG_FILE > .config

    if [ "$EXTEND_DRIVER" == "true" ]; then
        echo "🚀 Loading extend drivers"
        cat configs/Driver.config >> .config
    fi

    cat configs/$1.config >> .config && make defconfig
    echo "📋 Configuration Info: "
    cat .config
}

main() {

    config_names=$(ls "$LUCI_DIR"/*.config | xargs -n 1 basename | sed 's/\.config$//')
    echo "📕Configuration files: $config_names"

    if [ "$(echo $LUCI_CONFIG | tr '[:upper:]' '[:lower:]')" == "all" ]; then
        # Compile OpenWrt with all configuration files
        for config in $config_names; do
            echo "🚀 Compiling OpenWrt with $config"
            init_config "$config"
            compile_openwrt
            firmware_rename
        done 
    else
        if echo "$config_names" | grep -i -qw "$LUCI_CONFIG"; then
            echo "🚀 Compiling OpenWrt with $LUCI_CONFIG"
            init_config "$LUCI_CONFIG"
            compile_openwrt
            firmware_rename
        else
            echo "❌ Configuration $LUCI_CONFIG not found in available configurations."
        fi
    fi
}
main;