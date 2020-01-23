#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Cited from コードの世界 by Matz
# 典型的なスペル・ミスを探す方法, 図6 文章のミスをチェックするスクリプト
#
# Usage: ./check_typo.rb FILENAME
#  e.g.: ./check_typo.rb source/testing.md

ARGF.each do |line|
  next if line.include? "ここまでで"
  next if line.include? "でできる"
  next if line.include? "でできます"
  next if line.include? "でである"
  print ARGF.file.path, " ",
    ARGF.file.lineno, ":",
    line if line.gsub!(/([へにおはがでな])\1/u, '[[\&]]')
end
