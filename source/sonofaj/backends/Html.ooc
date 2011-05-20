import io/[File, FileWriter, Writer]
import text/StringTokenizer
import structs/[ArrayList,HashMap]

import sonofaj/[Doc, Nodes, Repository, Visitor]
import sonofaj/backends/Backend

HtmlVisitor : class extends Visitor {
    html : HtmlWriter
    init : func(=html)
    
    visitFunction : func(node : SFunction) {
        visitFunction(node,"func")
    }
    
    visitClass : func(node : SClass) {
        identifier := node getIdentifier()
        html openTag("p","class")
        html writeHtmlLine(html getTag("span","cname","Class %s" format(html getHtmlType(identifier))))
        // Indent for members
        html indent()
        // Extends
        if(node extends_ != null && !node extends_ empty?()) {
            html write(HtmlWriter Ln)
            html writeHtmlLine(html getTag("span","extends","Extends %s" format(html getHtmlType(node getExtendsRef()))))
        }
        // Doc
        if(node doc != null && !node doc empty?()) {
            html write(HtmlWriter Ln)
            html writeHtmlLine(html getTag("span","doc",formatDoc(node doc)))
        }
        // Get members
        for(member in node members) {
            html write(HtmlWriter Ln)
            match (member node type) {
                case "method" => {
                    if(member node as SFunction hasModifier("static"))
                        visitFunction(member node as SFunction, "staticmethod")
                    else
                        visitFunction(member node as SFunction, "method")
                }
                case "field" => {
                    visitGlobalVariable(member node as SGlobalVariable, "field")
                }
                case "enum" => {
                    visitEnum(member node as SEnum)
                }
            }
        }
        html dedent()
        html closeTag("p")
    }
    
    visitFunction : func ~directive(node : SFunction, directive : String) {
        signature := node getSignature(true)
        body : String = ""
        // Get name
        nameNsuffix : String
        if(signature find("(",0) != -1) {
            nameNsuffix = signature substring(0,signature find("(",0))
        } else if(signature find("->",0) != -1) {
            nameNsuffix = signature substring(0,signature find("->",0))
        } else {
            // No arguments, no return type
            nameNsuffix = signature
        }
        name := nameNsuffix substring(0,nameNsuffix find("~",0))
        body += html getTag("span","fname",name)
        // Get suffix
        if(name != nameNsuffix) {
            suffix := nameNsuffix substring(nameNsuffix find("~",0))
            body += html getTag("span","fsuffix",suffix)
        }
        // Get argument types
        argStr := signature substring(signature find("(",0) + 1, signature find(")",0))
        if(argStr != null && !argStr empty?() && argStr != signature) {
            body += "( "
            args := argStr split(',')
            for(arg in args) {
                original := arg
                arg = arg trimLeft()
                if(!arg startsWith?(":")) {
                    // It has a name :)
                    body += html getTag("span","argname",arg substring(0,arg find(":",0)+2))
                    arg = arg substring(arg find(":",0)+1)
                }
                // Get the type
                if(arg findAll(":") getSize() >= 2) {
                    dir := arg substring(arg findAll(":")[0]+1,arg findAll(":")[1])
                    type := arg substring(arg findAll(":")[1]+1,arg length()-1)
                    body += html getHtmlType(type,dir)
                } else {
                    // Maybe it is VarArgs (should fix that to point to lang/VarArgs) or a Func type
                    body += arg
                }
                if(args indexOf(original) != args getSize() - 1) {
                    body += ", "
                }
            }
            body += " )"
        }
        // Get return type
        if(signature find("->",0) != -1) {
            returnType := signature substring(signature find("->",0)+2)
            returnType = returnType trimLeft()
            retBody := " -> "
            if(returnType startsWith?(":")) {
                dir := returnType substring(returnType findAll(":")[0]+1,returnType findAll(":")[1])
                type := returnType substring(returnType findAll(":")[1]+1)
                retBody += html getHtmlType(type,dir)
            } else {
                retBody += returnType
            }
            body += html getTag("span","freturn",retBody)
        }
        // Get doc string
        if(node doc != null && !node doc empty?()) {
            body += HtmlWriter Ln
            html indent()
            body += html htmlIndent() + html getTag("span","doc",formatDoc(node doc))
            html dedent()
        }
        // Close function block :) 
        body += HtmlWriter Ln
        html writeHtmlLine(html getTag("span",directive,body))
    }
    
    visitCover : func(node : SCover) {
    }
    
    visitEnum : func(node : SEnum) {
    }
    
    visitGlobalVariable : func(node : SGlobalVariable) {
        visitGlobalVariable(node,"var")
    }
    
    visitGlobalVariable : func ~directive(node : SGlobalVariable, directive : String) {
    }
}

HtmlWriter : class {
    writer : Writer
    module : SModule
    indentLevel : UInt = 0
    
    init : func(=module,=writer)
    
    getHtmlType : func(ref : String, directive := "class") -> String {
        ref = ref trimRight()
        ref = ref trimLeft()
        pointer := false
        reference := false
        if(ref endsWith?("*")) {
            pointer = true
            ref = ref substring(0,ref length()-1)
        } else if(ref endsWith?("&")) {
            reference = true
            ref = ref substring(0,ref length()-1)
        }
        
        if(ref startsWith?("`~") && ref endsWith?("`")) {
            ref = ref substring(2,ref length()-1)
        }
        
        ret := "<a class=\"%s\" href=\"" format(directive)
        
        modulePath := ref substring(0,ref find(" ",0)) // Get the module path
        root := modulePath substring(0,modulePath find("/",0)) // Get the root folder of the module
        thisRoot := module path substring(0,module path find("/",0)) // Get the root of the current module
        if(root != thisRoot) {
            ret += "../" times(module path findAll("/") getSize() + 1) + "html/" + modulePath
        } else {
            ret += "../" times(module path findAll("/") getSize()) + root + "/" + modulePath substring(modulePath find("/",0)+1)
        }
        
        typeStr := ref substring(ref find(" ",0) + 1)
        if(pointer) typeStr+="*"
        if(reference) typeStr+="&"
        
        
        ret += ".html\">%s</a>" format(typeStr)
        ret
    }
    
    writeModuleLine : func(path : String) {
        writeLine("<h1 class=\"module\">" + path + "</h1>")
    }
    
    writeLine : func(str : String) {
        write(str+"\n")
    }
    
    writeHtmlLine : func(str : String) {
        writeHtml(str+"\n")
    }
    
    openTag : func(tag, class_ : String) {
        writeHtmlLine("<%s class=\"%s\">" format(tag,class_))
    }
    
    closeTag : func(tag : String) {
        writeHtmlLine("</%s>" format(tag))
    }
    
    writeBeginning : func(title : String) {
        this writeLine("<html>"). indent(). writeLine("<head><title>"+title+"</title></head>"). writeLine("<body>"). indent(). writeLine("<div id=\"body\">"). indent()
    }
    
    writeEnd : func {
        this dedent(). writeLine("</div>"). dedent(). writeLine(""). writeLine("</body>"). dedent(). writeLine("</html>")
    }
    
    writeHtml : func(str : String) {
        writeNoIndent(htmlIndent() + str)
    }
    
    htmlIndent : func -> String {
        return "&nbsp;" times(4*(indentLevel-2))
    }
    
    getTag : func(tagName, class_, contents : String) -> String {
        return "<%s class=\"%s\">" format(tagName,class_) + contents + "</%s>" format(tagName)
    }
    
    Ln := static "\n<br/>\n<br/>\n"
    
    writeNoIndent : func(str : String) {
        writer write(str)
    }
    
    indent : func {
        indentLevel += 1
    }
    
    dedent : func {
        indentLevel -= 1
    }
    
    write : func(str : String) {
        writer write("    " times(indentLevel) + str)
    }
    
    close : func {
        writer close()
    }
}

HtmlBackend : class extends Backend {
    outPath : File

    init : func (=repo) {
        outPath = repo root getChild("html")
        outPath mkdirs()
    }
    
    handle : func(module : SModule) {
        if(module path != null && !module path empty?()) {
            ("Handling module " + module name + ".") println() 
            file := outPath getChild(module path + ".html") /* TODO: does this work in all cases? */
            file parent() mkdirs()
            html := HtmlWriter new(module,FileWriter new(file))
            visitor := HtmlVisitor new(html)
            html writeBeginning(module name) \
               .writeModuleLine(module path) \
               .writeLine("")
            visitor visitChildren(module)
            html writeEnd()
            html close()
            ("Module " + module name + " handled.") println()
        }
    }
    
    run : func {
        for(module in repo getModules()) {
            handle(module)
        }
    }
}

