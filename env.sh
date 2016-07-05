#!/bin/sh

export CRITIQUE_ROOT=`pwd`
export CRITIQUE_DEBUG=0
export CRITIQUE_EDITOR='subl -w %s:%d:%d'

export PERL5LIB="$CRITIQUE_ROOT/lib:$PERL5LIB"

critique () {
    perl $CRITIQUE_ROOT/bin/critique $@
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

critique-list-policies () {
    perlcritic --brutal --list $@
}
