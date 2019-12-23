#!/bin/sh
jekyll build
rm -rf /var/www/html/*
rsync -av _site/ /var/www/html/
