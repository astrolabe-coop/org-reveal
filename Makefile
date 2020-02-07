#!/usr/bin/make -f
# -*- makefile -*-
# ex: set tabstop=4 noexpandtab:
# -*- coding: utf-8 -*-
#
# SPDX-License: ISC
# SPDX-License-URL: https://spdx.org/licenses/ISC.html

default: help all
	@echo "# https://github.com/yjwen/org-reveal"


srcs?=$(wildcard *.org | sort)
objs?=${srcs:.org=.html}
target?=$(shell echo ${srcs:.org=} | head -n1)
reveal_url?=https://github.com/hakimel/reveal.js/
reveal_zip_url?=https://github.com/hakimel/reveal.js/archive/master.zip
reveal_dir?=./reveal.js
sudo?=sudo
deploy_branch?=gh-pages


help:
	@echo "# Usage:"
	@echo "#  make help # Usage"
	@echo "#  make setup # Install tools"
	@echo "#  make all # Build html"
	@echo "#  make start # View HTML in Web browser"
	@echo "#  make download # Download deps"
	@echo "#  make setup/debian setup download start # ..."
	@echo "# Config:"	
	@echo "#  srcs=${srcs}"
	@echo "#  objs=${objs}"
	@echo "#  target=${target}"

all: ${objs}
	ls $^

download: ${reveal_dir}
	ls $^

start: ${target}.html
	x-www-browser $<

clean:
	rm -rfv *~ */*/*~ tmp tmp.*

cleanall: clean
	find . -iname "*.html" -exec rm -v "{}" \;

setup/debian: /etc/debian_version
	-${sudo} apt-get update
	${sudo} apt-get install -y \
 emacs \
 git \
 sudo \
 unzip \
 wget \
 # EOL

setup: /etc/os-release
	@echo "# Please install tools, On debian: make setup/debian"
	emacs \
 --no-init-file  \
 --user ${USER} \
 --batch \
 --eval="(require 'package)" \
 --eval="(add-to-list 'package-archives \
  '(\"melpa\" . \"https://melpa.org/packages/\"))" \
 --eval='(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")' \
 --eval="(package-initialize)" \
 --eval="(package-show-package-list)" \
 --eval="(package-refresh-contents)" \
 --eval="(package-list-packages)" \
 --eval="(package-install 'org)" \
 --eval="(package-install 'htmlize)" \
 --eval="(package-install 'ox-reveal)" \
# EOL

%.html: %.org Makefile
	cd ${<D} \
&& \
 emacs \
 --no-init-file\
 --user ${USER} \
 --batch \
 --eval="(require 'org)" \
 --eval="(require 'org-gnus)" \
 --eval="(require 'ox-reveal)" \
 --find-file "${<F}" \
 --funcall org-reveal-export-to-html \
 # EOL

html: ${target}.html
	ls $<

all/%: ${srcs}
	for src in $^ ; do \
    target=$$(echo "$${src}" | sed -e 's|.org||g') ; \
    make target="$${target}" ${@F} \
    || exit $$? ; \
  done

${reveal_dir}:
	@mkdir -p ${@D}
	wget -O- ${reveal_zip_url} > reveal.js.zip
	unzip reveal.js.zip
	mv reveal.js-master ${@}
	@rm -f reveal.js.zip

deploy:
	-git commit -sam "WIP: About to deploy ${target}"
	git checkout ${deploy_branch} \
  || git checkout -b ${deploy_branch} master
	make html
	git add -f ${target}.html
	-git commit -am "WIP: Generated html ${target}"
	git checkout master

upload:
	git checkout master
	-git branch -D ${deploy_branch}
	 git checkout -b ${deploy_branch}
	-git commit -sam "WIP: About to download"
	make download
	git add -f "${reveal_dir}"
	-git commit -sam "WIP: Add ${reveal_dir}"
	${MAKE} all/deploy
	git checkout ${deploy_branch}
	echo "# About to push to origin in 5 secs ?"
	sleep 5 ; git push -f origin HEAD:gh-pages
	git checkout master
