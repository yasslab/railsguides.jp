#!/bin/sh

# Test Markdown files using 'check_typo.rb'

for article in `ls source/ja | grep md`
do
    echo "Testing ${article}"
    ruby check_typo.rb "./source/ja/${article}"
done
