#!/bin/bash

IGNORED_REGISTRIES=( \
    "https://registry.npmjs.org" \
    "https://npm.pkg.github.com" \
    "https://staging-packages.unity.com" \
);
OFFICIAL_REGISTRY=https://packages.unity.com
OPEN_UPM_REGISTRY=https://package.openupm.com



# check the package registry
REGISTRY=`jq -r '.publishConfig.registry' package.json | sed 's/\/$//'`
REGISTRY=${REGISTRY:-https://packages.unity.com/}
echo ">> check the custom package registry: $REGISTRY"

if [ -z "$REGISTRY" ]; then
    echo "`publishConfig.registry` in package.json is not specified."
    exit 1
elif [ `echo ${IGNORED_REGISTRIES[@]} | grep -q "$REGISTRY"` ]; then
    echo "$REGISTRY is an invalid registry for upm."
    exit 1
fi


# get package list from the official package registry
echo ">> get package list from the official package registry: "$OFFICIAL_REGISTRY
npm view com.unity.package-manager.metadata@latest searchablePackages --registry=$OFFICIAL_REGISTRY --json > official
cat official

# get package list from the package registry
echo ">> get package list from the package registry: "$REGISTRY

# [official]
if [ "$REGISTRY" == "$OFFICIAL_REGISTRY" ]; then
    echo "[]" > packages

# [openupm]
#   workaround for https://github.com/openupm/openupm/issues/68.
#   however, should use the '/-/all' endpoint after fixed.
elif [ "$REGISTRY" == "$OPEN_UPM_REGISTRY" ]; then
    echo "   -> openupm"
    echo "   -> workaround for https://github.com/openupm/openupm/issues/68."

    [ -d openupm_68 ] && rm -rf openupm_68
    mkdir openupm_68
    cd openupm_68

    git init
    git config core.sparsecheckout true
    git remote add origin https://github.com/openupm/openupm.git
    echo 'data/packages' > .git/info/sparse-checkout
    git pull origin master --depth=1

    echo "   -> check package availability."
    ls data/packages \
    | jq -rnR 'inputs | select(length>0) | rtrimstr(".yml")' \
    | xargs -I {} npm view --registry=$REGISTRY {} name \
    | jq -nR '[inputs | select(length>0)]' \
    > ../packages

    cd ..

# [other]
else
    curl -sL "$REGISTRY/-/all" | jq 'keys' > packages
fi
cat packages



# ignore packages
cat .upmignore | jq -nR '[inputs | select(length>0)]' > ignores
jq --slurpfile i ignores '. - map(select(startswith( $i[0][] )))' packages > fixed_packages
cat fixed_packages



# merge searchable packages.
echo ">> merge searchable packages"
jq --slurpfile o official --slurpfile p fixed_packages '.searchablePackages = ($o[0] + $p[0] | sort | unique)' package.json > package.json.tmp
