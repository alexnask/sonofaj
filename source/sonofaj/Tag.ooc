import structs/ArrayList
import text/StringBuffer

ParsingError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}

Tag: class {
    value: String
    arguments: ArrayList<Tag>

    init: func (=value) {
        this(value, null)    
    }

    init: func ~withArguments (=value, =arguments) {
    
    }

    hasArguments: func -> Bool {
        arguments != null
    }

    parse: static func (iter: Iterator<Char>, lastChar: Char*) -> Tag {
        buf := StringBuffer new()
        tag: Tag
        /* first: skip whitespaces and commas. */
        next: Char = iter next()
        while(next isWhitespace() || next == ',') {
            next = iter next()
        }
        /* then: read the tag value. */
        while(!next isWhitespace() && next != '(' && next != ',' && next != ')') {
            buf append(next)
            if(!iter hasNext())
                break
            next = iter next()
        }
        lastChar@ = next
        tag = Tag new(buf toString())
        /* then: do we have arguments? */
        if(next == '(') {
            tag arguments = ArrayList<Tag> new()
            while(true) {
                thisLastChar: Char
                tag arguments add(parse(iter, thisLastChar&))
                lastChar@ = thisLastChar
                /* no more arguments. */
                if(thisLastChar == ')') {
                    break
                } else if(thisLastChar == ',') {
                    continue
                } else {
                    ParsingError new("Huh! I didn't expect '%c'!" format(thisLastChar)) throw()
                    /* NOBODY expects '%c'!" */
                }
            }
        }
        return tag
    }

    parse: static func ~string (str: String) -> Tag {
        lastChar: Char
        parse(str iterator(), lastChar&)
    }
}
