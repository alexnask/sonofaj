sonofaj: source/sonofaj.ooc source/sonofaj/*.ooc source/sonofaj/*/*.ooc repo
	ooc -sourcepath=source -noclean -v -g -driver=sequence sonofaj.ooc

repo: get-sdk.ooc
	ooc -backend=json -outpath=repo get-sdk.ooc

clean:
	rm -rfv sonofaj repo ooc_tmp

.phony: clean

