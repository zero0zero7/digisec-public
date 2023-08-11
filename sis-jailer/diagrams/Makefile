default: arch-pilot.png arch-ga.png

%.png: %.pdf
	convert $^ -background white -alpha remove $@

%.pdf: %.tex
	latexmk -pdf $<
