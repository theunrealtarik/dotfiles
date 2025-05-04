#!/bin/bash
[ -n "$1" ] && file=$1
nvim --server ~/.cache/nvim/godot.pipe --remote-send ':e '$file'<CR>'
