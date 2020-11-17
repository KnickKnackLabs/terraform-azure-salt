#!/usr/bin/env bash

set -euxo pipefail

# Set Walmart Azure apt repos
cat > /etc/apt/sources.list <<- EOF
	deb http://azscrepo.cloud.wal-mart.com/ubuntu/ bionic main restricted universe multiverse
	deb http://azscrepo.cloud.wal-mart.com/ubuntu/ bionic-updates main restricted universe multiverse
	deb http://azscrepo.cloud.wal-mart.com/ubuntu/ bionic-security main restricted universe multiverse
EOF
