import structs/ArrayList
import text/StringTokenizer

formatDoc: func (doc: String) -> String {
    docStripped := doc
    if(docStripped startsWith?("/**")) {
        docStripped = docStripped substring(3)
    }
    if(docStripped endsWith?("*/")) {
        docStripped = docStripped substring(0, docStripped length() - 2)
    }
    lines := docStripped split('\n', true)
    maxIndentation := -1
    // find longest common indentation
    for(idx in 1..lines getSize()) {
        line := lines[idx] as String
        // calculate current indentation
        indentation := 0
        foundChar := false
        for(chr in line) {
            if(chr whitespace?() || chr == '*') { // '*' is also whitespace.
                indentation += 1
            } else {
                foundChar = true
                break
            }
        }
        // shorter than max indentation? but only if we got a real char.
        if(foundChar) {
            if(foundChar && (maxIndentation == -1 || indentation < maxIndentation)) {
                maxIndentation = indentation
            }
        } else {
            // haven't found real char? empty line.
            lines[idx] = ""
        }
    }
    // now strip the calculated indentation
    lines[0] = lines[0] trim("\t *") // the first line is just trimmed.
    for(idx in 1..lines getSize()) {
        if(!lines[idx] empty?())
            lines[idx] = lines[idx] substring(maxIndentation)
    }
    lines join('\n')
}
