import text/StringBuffer

formatDoc: func (doc: String) -> String {
    afterNewline := true
    buf := StringBuffer new()
    docStripped := doc substring(3, doc length() - 2) /* without / ** ... * / */
    for(c: Char in docStripped) {
        if(afterNewline) {
            if(c != ' ' && c != '*' && c != '\t') {
                afterNewline = false
            } else {
                continue
            }
        }
        if(c == '\n') {
            afterNewline = true
        }
        buf append(c)
    }
    buf toString()
}
