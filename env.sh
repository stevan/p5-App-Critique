#!/bin/sh

export PERL5LIB="./lib:$PERL5LIB"
export CRITIQUE_DEBUG=1

critique () {
    perl bin/critique $@
}

critique-open-dir () {
    open ~/.critique
}

critique-delete-dir () {
    set -x
    rm -rfv ~/.critique
    set +x
}

critique-debug-off () {
    export CRITIQUE_DEBUG=0
}

critique-debug-on () {
    export CRITIQUE_DEBUG=1
}

