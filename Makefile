icon:
	webkit2png --transparent \
		--fullsize \
		--dir=${TMPDIR} \
		--filename=icon \
		Resources/icon-template.html
	open ${TMPDIR}icon-full.png

pngcrush:
	@for f in $(shell find Resources -name '*.png'); do pngcrush -ow -l 9 $$f; done
