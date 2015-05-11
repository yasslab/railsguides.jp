#!/bin/sh

# Update HTMLs using 'archive.zip' downloaded by GTT

ruby allocate.rb
rm -rf output/ja
bundle exec rake guides:generate:html GUIDES_LANGUAGE=ja
cp ./source/ja/favicon.ico ./output/ja

# Then, manually type these commands:
#   $ git add .
#   $ git commit -m "Publish foo bar"
#   $ git push origin japanese
#   $ git push heroku japanese:master
