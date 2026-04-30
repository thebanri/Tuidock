#!/bin/bash

# Tuidock Installation Script
# This script detects the OS and architecture, downloads the latest release from GitHub,
# and installs it to a directory in the user's PATH.

set -e

OWNER="thebanri"
REPO="Tuidock"
BINARY_NAME="tuidock"

# Color constants
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

printf "${BLUE}🚢 Installing Tuidock...${NC}\n"

# Detect OS
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "${OS}" in
  linux*)   OS='Linux' ;;
  darwin*)  OS='Darwin' ;;
  msys*|cygwin*|mingw*) OS='Windows' ;;
  *)        printf "${RED}Unsupported OS: ${OS}${NC}\n"; exit 1 ;;
esac

# Detect Architecture
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64|amd64) ARCH='x86_64' ;;
  arm64|aarch64) ARCH='arm64' ;;
  *)            printf "${RED}Unsupported architecture: ${ARCH}${NC}\n"; exit 1 ;;
esac

# Get latest version from GitHub API
printf "${BLUE}🔍 Finding latest version...${NC}\n"
LATEST_RELEASE_URL="https://api.github.com/repos/${OWNER}/${REPO}/releases/latest"
VERSION=$(curl -sL "${LATEST_RELEASE_URL}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

if [ -z "${VERSION}" ]; then
  printf "${RED}Failed to fetch latest version. Please check your internet connection or GitHub API limits.${NC}\n"
  exit 1
fi

printf "${GREEN}✨ Found version ${VERSION}${NC}\n"

# Construct download URL (matching GoReleaser pattern)
# Pattern: tuidock_0.1.0_Linux_x86_64.tar.gz
EXT="tar.gz"
if [ "${OS}" = "Windows" ]; then
  EXT="zip"
fi

FILENAME="${BINARY_NAME}_${VERSION}_${OS}_${ARCH}.${EXT}"
DOWNLOAD_URL="https://github.com/${OWNER}/${REPO}/releases/download/v${VERSION}/${FILENAME}"

# Create a temporary directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

printf "${BLUE}📥 Downloading ${FILENAME}...${NC}\n"
curl -sL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${FILENAME}"

# Extract
printf "${BLUE}📦 Extracting...${NC}\n"
if [ "${EXT}" = "tar.gz" ]; then
  tar -xzf "${TMP_DIR}/${FILENAME}" -C "${TMP_DIR}"
else
  unzip -q "${TMP_DIR}/${FILENAME}" -d "${TMP_DIR}"
fi

# Install
INSTALL_DIR="/usr/local/bin"
if [ ! -d "${INSTALL_DIR}" ] || [ ! -w "${INSTALL_DIR}" ]; then
  # Fallback to a user-writable directory if /usr/local/bin isn't available
  INSTALL_DIR="${HOME}/.local/bin"
  mkdir -p "${INSTALL_DIR}"
  printf "${BLUE}⚠️  /usr/local/bin is not writable. Installing to ${INSTALL_DIR} instead.${NC}\n"
  printf "${BLUE}Make sure ${INSTALL_DIR} is in your PATH.${NC}\n"
fi

# Windows handling for binary name
BIN_SOURCE="${TMP_DIR}/${BINARY_NAME}"
if [ "${OS}" = "Windows" ]; then
  BIN_SOURCE="${BIN_SOURCE}.exe"
  BINARY_NAME="${BINARY_NAME}.exe"
fi

printf "${BLUE}🚀 Moving binary to ${INSTALL_DIR}/${BINARY_NAME}...${NC}\n"
if [ -w "${INSTALL_DIR}" ]; then
  mv "${BIN_SOURCE}" "${INSTALL_DIR}/${BINARY_NAME}"
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
else
  sudo mv "${BIN_SOURCE}" "${INSTALL_DIR}/${BINARY_NAME}"
  sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
fi

printf "${GREEN}✅ Tuidock ${VERSION} installed successfully!${NC}\n"
printf "Run it by typing: ${BLUE}${BINARY_NAME}${NC}\n"
