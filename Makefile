sonofaj: source/sonofaj.ooc source/sonofaj/*.ooc source/sonofaj/*/*.ooc
	ooc -sourcepath=source -noclean -v -g sonofaj.ooc

repo: test.ooc
	ooc -backend=json -outpath=repo test.ooc

clean:
	rm -f sonofaj

.phony: clean

