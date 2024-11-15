#!/bin/bash

# Re-generate the GitHub workflows based on templates. We do not use a matrix
# build strategy in GitHub worflows to reduce overall build time and avoid
# pulling the same base container image multiple time, once for each individual
# job.

set -euo pipefail
# set -x

main() {
    # Re-run for each target
    if [[ ${#} -eq 0 ]]; then
        ${0} \
        'quay.io/fedora/fedora-coreos' \
        'next' \
        'Fedora CoreOS (next)' \
        'fedora-coreos' \
        'quay.io/travier' \
        'fedora-coreos-sysexts'
        
        ${0} \
        'quay.io/fedora-ostree-desktops/kinoite' \
        '41' \
        'Fedora Kinoite (41)' \
        'fedora-kinoite' \
        'quay.io/travier' \
        'fedora-kinoite-sysexts'
        
        ${0} \
        'quay.io/fedora-ostree-desktops/silverblue' \
        '41' \
        'Fedora Silverblue (41)' \
        'fedora-silverblue' \
        'quay.io/travier' \
        'fedora-silverblue-sysexts'
        
        ${0} \
        'ghcr.io/ublue-os/kinoite-main' \
        '41' \
        'Ublue Kinoite (41)' \
        'kinoite-main' \
        'ghcr.io/herobrauni' \
        'kinoite-main-sysexts'
        
        exit 0
    fi
    
    local -r image="${1}"
    local -r release="${2}"
    local -r name="${3}"
    local -r shortname="${4}"
    local -r registry="${5}"
    local -r destination="${6}"
    
    if [[ ! -d .github ]] || [[ ! -d .git ]]; then
        echo "This script must be run at the root of the repo"
        exit 1
    fi
    
    # Get the list of sysexts for a given target
    sysexts=()
    for s in $(git ls-tree -d --name-only HEAD | grep -Ev ".github|templates"); do
        pushd "${s}" > /dev/null
        if [[ $(just targets | grep -c "${image}:${release}") == "1" ]]; then
            sysexts+=("${s}")
        fi
        popd > /dev/null
    done
    
    # Generate EROFS sysexts workflows
    {
        sed \
        -e "s|%%IMAGE%%|${image}:${release}|g" \
        -e "s|%%RELEASE%%|${release}|g" \
        -e "s|%%NAME%%|${name}|g" \
        -e "s|%%SHORTNAME%%|${shortname}|g" \
        templates/sysexts_header
        echo ""
        for s in "${sysexts[@]}"; do
            sed "s|%%SYSEXT%%|${s}|g" templates/sysexts_body
            echo ""
        done
        cat templates/sysexts_footer
    } > ".github/workflows/sysexts-${shortname}-${release}.yml"
    
    #     # Generate container sysexts workflows
    #     {
    #         sed \
    #         -e "s|%%IMAGE%%|${image}|g" \
    #         -e "s|%%RELEASE%%|${release}|g" \
    #         -e "s|%%NAME%%|${name}|g" \
    #         -e "s|%%REGISTRY%%|${registry}|g" \
    #         -e "s|%%DESTINATION%%|${destination}|g" \
    #         templates/containers_header
    #         echo ""
    #         for s in "${sysexts[@]}"; do
    #             sed "s|%%SYSEXT%%|${s}|g" templates/containers_build
    #             echo ""
    #         done
    #         cat templates/containers_logincosign
    #         for s in "${sysexts[@]}"; do
    #             sed "s|%%SYSEXT%%|${s}|g" templates/containers_pushsign
    #             echo ""
    #         done
    #     } > ".github/workflows/containers-${shortname}-${release}.yml"
}

main "${@}"
