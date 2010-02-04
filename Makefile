sonofaj: source/sonofaj.ooc source/sonofaj/*.ooc source/sonofaj/*/*.ooc repo
	ooc -sourcepath=source -noclean -v -g -driver=sequence sonofaj.ooc

repo: get-sdk.ooc
	ooc -backend=json -outpath=repo get-sdk.ooc

clean:
	rm -f sonofaj

.phony: clean

