#!/bin/bash -e
# Install kubectl
set -o pipefail

install_kubectl(){
	LATEST_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
	ARCH="$(arch)"
	case "$ARCH" in
			x86_64) ARCH="amd64" ;;
	esac
	BIN="$(command -v kubectl; true)"
	if [[ -z "$BIN" ]]; then
		BIN_VERSION="Not installed"
	else
		BIN_VERSION="$(${BIN} version --client --output json | jq -r ".clientVersion.gitVersion" || echo "None")"
	fi

	if [[ "${BIN_VERSION}" != "${LATEST_VERSION}" ]]; then
		URL="https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl"
		echo "Installing kubectl from '$URL'"
		curl -LO --fail --silent "${URL}"
		chmod a+x "kubectl"
		mkdir -p "${HOME}/.local/bin"
		sudo mv "kubectl" "/usr/local/bin/kubectl"
		kubectl completion "$(basename "${SHELL}")" | sudo tee /etc/bash_completion.d/kubectl >/dev/null
	fi
	kubectl version --client --output yaml
}

install_kubectl
