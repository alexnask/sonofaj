sonofaj: source/sonofaj.ooc source/sonofaj/*.ooc source/sonofaj/*/*.ooc repo
	ooc -sourcepath=source -noclean -v -vv -g -driver=sequence sonofaj.ooc

get-sdk.ooc:
	python generate-get-sdk.py

repo: get-sdk.ooc
	ooc -backend=json -outpath=repo get-sdk.ooc

docs: sonofaj repo
	./sonofaj -r repo -b sphinx

clean:
	rm -rfv sonofaj repo ooc_tmp get-sdk.ooc

.phony: clean

