#!/bin/bash -e
set -o pipefail
SCRIPT_DIR="$(dirname "$(realpath $0)")"

usage() {
  echo "
Usage:
    ${0##*/} [options]
Setup a k3s cluster on the TARGET server.

Mandatory argumets:
    -t, --to TARGET
        Server on which to deploy the cluster.

Optional arguments:
    -d, --debug
        Activate tracing/debug mode.
    -h, --help
        Display this message.
Example:
    ${0##*/} --to myserver
" >&2
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -t | --to)
      shift
      TARGET="$1"
      ;;
    -d | --debug)
      set -x
      DEBUG="--debug"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      # End of arguments
      break
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
    esac
    shift
  done
}

init() {
    if [ -z "$TARGET" ]; then
        echo "Missing argument: --to TARGET" >&2
        usage
        exit 1
    fi
    ANSIBLE_DIR="${SCRIPT_DIR}/ansible"
}

render_template() {
    sed -e "s/^\( *\)TARGET:/\1$TARGET:/" "hosts.in.yml" > "hosts.yml"
}

run_playbook() {
    ansible-playbook -v -i "hosts.yml" "sites.yml"
}

get_kubeconfig() {
    mkdir -p "${HOME}/.kube"
    scp "${TARGET}:.kube/config" "${HOME}/.kube/config"
}

check_cluster() {
    echo; echo "[Nodes]"
    kubectl get nodes
    echo; echo "[Deployments]"
    kubectl get deployment --all-namespaces
}

install() {
    reset
    date
    cd "${ANSIBLE_DIR}"
    render_template
    run_playbook
    cd - 2>/dev/null
    get_kubeconfig
    check_cluster
    date
}

main() {
    parse_args "$@"
    init
    install
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  main "$@"
fi
