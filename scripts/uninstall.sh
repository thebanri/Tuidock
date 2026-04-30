#!/bin/bash

# Tuidock Uninstallation Script
# This script removes the Tuidock binary from the system.

set -e

BINARY_NAME="tuidock"

# Color constants
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

printf "${BLUE}🚢 Uninstalling Tuidock...${NC}\n"

# Detect OS
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
if [[ "${OS}" == *"msys"* || "${OS}" == *"cygwin"* || "${OS}" == *"mingw"* ]]; then
  BINARY_NAME="tuidock.exe"
fi

# Potential installation paths
PATHS=(
  "/usr/local/bin/${BINARY_NAME}"
  "${HOME}/.local/bin/${BINARY_NAME}"
)

REMOVED=false

for path in "${PATHS[@]}"; do
  if [ -f "$path" ]; then
    printf "${BLUE}🗑️ Removing $path...${NC}\n"
    if [ -w "$(dirname "$path")" ]; then
      rm "$path"
    else
      sudo rm "$path"
    fi
    REMOVED=true
  fi
done

if [ "$REMOVED" = true ]; then
  printf "${GREEN}✅ Tuidock has been successfully removed from your system.${NC}\n"
else
  printf "${RED}❌ Tuidock binary not found in standard installation paths.${NC}\n"
  exit 1
fi
