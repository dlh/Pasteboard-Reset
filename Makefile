status-icon:
	webkit2png --transparent \
		--fullsize \
		--dir=${TMPDIR} \
		--filename=status-icon \
		Resources/status-icon-template.html
	open ${TMPDIR}status-icon-full.png
