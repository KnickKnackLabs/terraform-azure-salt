#!/usr/bin/env bash

set -euxo pipefail

# Set Walmart Azure apt repos
cat > /etc/apt/sources.list <<- EOF
	deb http://aze2repo.cloud.wal-mart.com/ubuntu/ xenial main restricted universe multiverse
	deb http://aze2repo.cloud.wal-mart.com/ubuntu/ xenial-updates main restricted universe multiverse
	deb http://aze2repo.cloud.wal-mart.com/ubuntu/ xenial-security main restricted universe multiverse
EOF
