#!/usr/bin/env bash

inotifywait -q -m -e close_write *.cfg src/*.s src/*.inc |
while read -r filename event; do
	make $1
done