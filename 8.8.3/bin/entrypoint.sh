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

if ! cat ${STACK_ROOT}/config.yaml | grep "ghc-options" > /dev/null; then
  echo -e "ghc-options:\n  \"\$everything\": -haddock -j${CPU_CORES} -optl-Fuse-ld=lld\n" >> ${STACK_ROOT}/config.yaml
fi

if ! cat ${STACK_ROOT}/config.yaml | grep "configure-options" > /dev/null; then
  echo -e "configure-options:\n  \"\$everything\":\n    - \"--ld-options='-fuse-ld=lld'\"\n    - \"--with-ld=ld.lld\"\n" >> ${STACK_ROOT}/config.yaml
fi

case "$1" in
  "--wait" )
    trap : TERM INT
    sleep infinity & wait;;
  "--build" )
    exec stack build --test --no-run-tests --fast --allow-different-user --ghc-options "-j$CPU_CORES +RTS -N -A128m -RTS";;
  "--build-watch" )
    exec stack build --test --no-run-tests --file-watch --fast --allow-different-user --ghc-options "-j$CPU_CORES +RTS -N -A128m -RTS";;
  "--test" )
    exec stack test --fast --allow-different-user --ghc-options "-j$CPU_CORES +RTS -N -A128m -RTS";;
  "--watch" )
    exec stack test \
      --fast \
      --allow-different-user \
      --file-watch \
      --test-arguments "--rerun --failure-report .hspec-failures --rerun-all-on-success" \
      --ghc-options "-j$CPU_CORES +RTS -N -A128m -RTS";;
  "--clean" )
    exec stack clean;;
  "--format" )
    find ./{app,src,test} -name '*.hs' -not -path '*/.stack-work/*' -not -path '*/.var/*' | xargs -I{} -n 1 -P $CPU_CORES bash -c "stylish-haskell -i {} && brittany --indent=4 --write-mode=inplace {}";;
  "--install" )
    exec stack install --test --no-run-tests --fast --ghc-options "-j$CPU_CORES +RTS -N -A128m -RTS";;
  * )
    exec $@;;
esac
