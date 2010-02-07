import structs/ArrayList
import text/[StringBuffer, StringTokenizer]

formatDoc: func (doc: String) -> String {
    docStripped := doc substring(3, doc length() - 2) /* without / ** ... * / */
    lines := docStripped split('\n', true) toArrayList() as ArrayList<String>
    maxIndentation := -1
    // find longest common indentation
    for(idx in 1..lines size()) {
        line := lines[idx] as String
        // calculate current indentation
        indentation := 0
        foundChar := false
        for(chr in line) {
            if(chr isWhitespace() || chr == '*') { // '*' is also whitespace.
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
    for(idx in 1..lines size()) {
        if(!lines[idx] isEmpty())
            lines[idx] = lines[idx] substring(maxIndentation)
    }
    lines join('\n')
}
