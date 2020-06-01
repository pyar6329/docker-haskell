#!/bin/bash

GITCONFIG=$(cat << 'EOF'
[credential]
  helper = store
[url "https://github.com/"]
  insteadOf = ssh://git@github.com/
  insteadOf = git@github.com:
EOF
)

if [ -n "${GITHUB_TOKEN}" ]; then
  if ! [ -e "${HOME}/.git-credentials" ]; then
    echo "https://${GITHUB_TOKEN}:@github.com" > ${HOME}/.git-credentials
  fi
  if ! [ -e "${HOME}/.gitconfig" ]; then
    echo "${GITCONFIG}" > ${HOME}/.gitconfig
  fi
fi

if ! [ -e "${STACK_ROOT}" ]; then
  mkdir -p ${STACK_ROOT}
fi

if ! [ -e "${STACK_ROOT}/global-project" ]; then
  mv ${HOME}/.stack_base/global-project ${STACK_ROOT}/global-project
fi

if ! [ -e "${STACK_ROOT}/config.yaml" ]; then
  mv ${HOME}/.stack_base/config.yaml ${STACK_ROOT}/config.yaml
fi

rm -rf ${HOME}/.stack_base

CPU_CORES=$(grep -c processor /proc/cpuinfo)

case "$1" in
  "--wait" )
    trap : TERM INT
    sleep infinity & wait;;
  "--build" )
    exec stack build --test --no-run-tests --fast -j$CPU_CORES --ghc-options '+RTS -N -A128m -RTS';;
  "--test" )
    exec stack test --fast -j$CPU_CORES --ghc-options '+RTS -N -A128m -RTS';;
  "--watch" )
    exec stack test \
      --fast \
      -j$CPU_CORES \
      --file-watch \
      --test-arguments '--rerun --failure-report .hspec-failures --rerun-all-on-success' \
      --ghc-options '+RTS -N -A128m -RTS';;
  "--clean" )
    exec stack clean;;
  "--format" )
    find ./{app,src,test} -name '*.hs' -not -path '*/.stack-work/*' -not -path '*/.var/*' | xargs -I{} -n 1 -P $CPU_CORES bash -c "stylish-haskell -i {} && brittany --indent=4 --write-mode=inplace {}";;
  "--install" )
    exec stack install --test --no-run-tests --fast -j$CPU_CORES --ghc-options '+RTS -N -A128m -RTS';;
  * )
    exec $@;;
esac
