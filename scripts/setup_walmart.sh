#!/usr/bin/env bash

set -euxo pipefail

# Set up workspace
WORKSPACE_DIR=$(mktemp -d)
pushd $WORKSPACE_DIR

# Run Walmart scripts
declare -a SCRIPT_URLS=(
    "https://repository.walmart.com/content/repositories/pangaea_releases/com/walmart/platform/torbit/azure/torbit-ubuntu/az_dhcp_config_ubuntu.sh"
    "https://repository.walmart.com/content/repositories/pangaea_releases/com/walmart/platform/torbit/azure/torbit-ubuntu/az_dns_update_ubuntu.sh"
    "https://repository.walmart.com/content/repositories/pangaea_releases/com/walmart/platform/torbit/azure/torbit-ubuntu/install_az_dns_update_ubuntu.sh"
    "https://repository.walmart.com/content/repositories/pangaea_releases/com/walmart/platform/torbit/azure/torbit-ubuntu/update_ubuntu_repo.sh"
    "https://repository.walmart.com/content/repositories/pangaea_releases/com/walmart/platform/torbit/azure/torbit-ubuntu/UbuntuMasterScript.sh"
)

for url in "${SCRIPT_URLS[@]}"; do
    curl -sL $url -o $(basename $url)
done

chmod +x UbuntuMasterScript.sh
sudo ./UbuntuMasterScript.sh

# Clean up workspace
popd
rm -r $WORKSPACE_DIR
