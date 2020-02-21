#!/bin/bash

if [ -n "${PACKAGE_NAME}" ]; then
    echo ">> add searchable packages: ${PACKAGE_NAME}"
    cat .upmignore | jq -nR '[inputs | select(length>0)]' > ignores
    jq --arg n "${PACKAGE_NAME}" '[$n] - ([$n] | map(select(startswith( . ))))' ignores > fixed_packages
    jq --slurpfile p fixed_packages '.searchablePackages = (.searchablePackages + $p[0] | sort | unique)' package.json > package.json.tmp
else
    ./update.sh
fi

echo ">> diff with package.json:"
diff package.json.tmp package.json || mv package.json.tmp package.json
