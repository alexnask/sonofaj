sonofaj: source/sonofaj.ooc source/sonofaj/*.ooc
	ooc -sourcepath=source -noclean -v -g sonofaj.ooc

clean:
	rm -f sonofaj

.phony: clean

