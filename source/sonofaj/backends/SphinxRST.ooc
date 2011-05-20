import io/[File, FileWriter, Writer]
import text/StringTokenizer
import structs/[ArrayList,HashMap]

import sonofaj/[Doc, Nodes, Repository, Visitor]
import sonofaj/backends/Backend

RSTWriter: class {
    writer: Writer
    indentLevel: Int
    indentString: String

    init: func (=writer) {
        indentString = ""
    }

    resetIndent: func (=indentLevel) {
        indentString = "    " times(indentLevel)
    }

    indent: func {
        resetIndent(indentLevel + 1)
    }

    dedent: func {
        resetIndent(indentLevel - 1)
    }

    writeLine: func (line: String) {
        if(line contains?('\n')) {
            for(newLine in line split('\n', true)) {
                writeLine(newLine)
            }
        } else {
            writer write(indentString) .write(line) .write("\n")
        }
    }

    close: func {
        writer close()
    }
}

RSTVisitor: class extends Visitor {
    rst: RSTWriter

    init: func (=rst) {}

    visitFunction: func ~withDirective (node: SFunction, directive: String) {
        // Works fine =D
        rst writeLine(".. %s:: %s" format(directive, node getSignature(true)))
        // stuff.
        rst indent()
        rst writeLine("")
        // doc
        if(node doc != null) {
            rst writeLine(formatDoc(node doc))
            rst writeLine("")
        }
        // end stuff.
        rst dedent()
    }
    
    visitFunction: func (node: SFunction) {
        visitFunction(node, "function")
    }

    visitGlobalVariable: func ~withDirective (node: SGlobalVariable, directive: String) {
        rst writeLine(".. %s:: %s -> %s" format(directive, node name, node getTypeRef())) .writeLine("")
    }

    visitGlobalVariable: func (node: SGlobalVariable) {
        visitGlobalVariable(node, "var")
    } 

    visitClass: func (node: SClass) {
        rst writeLine(".. class:: %s" format(node getIdentifier()))
        // stuff!
        rst indent()
        rst writeLine("")
        // extends
        if(node extends_ != null) {
            rst writeLine(":extends: %s" format(node getExtendsRef()))
        }
        // doc
        if(node doc != null) {
            rst writeLine(formatDoc(node doc))
            rst writeLine("")
        }
        // members.
        for(member in node members) {
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
        rst dedent()
    }
 
    visitCover: func (node: SCover) {
        rst writeLine(".. cover:: %s" format(node getIdentifier()))
        // stuff!
        rst indent()
        rst writeLine("")
        // extends
        if(node extends_ != null) {
            rst writeLine(":extends: %s" format(node getExtendsRef()))
        }
        // from
        if(node from_ != null) {
            rst writeLine(":from: ``%s``" format(node from_))
        }
        // doc
        if(node doc != null) {
            rst writeLine(formatDoc(node doc))
            rst writeLine("")
        }
        // members.
        for(member in node members) {
            match (member node type) {
                case "method" => {
                    visitFunction(member node as SFunction, "method")
                }
                case "field" => {
                    visitGlobalVariable(member node as SGlobalVariable, "field")
                }
            }
        }
        rst dedent()
    }
    
    visitEnum: func (node: SEnum) {
        rst writeLine(".. enum:: %s" format(node getIdentifier()))
        // stuff!
        rst indent()
        rst writeLine("")
        // doc
        if(node doc != null) {
            rst writeLine(formatDoc(node doc))
            rst writeLine("")
        }
        // members.
        for(member in node members) {
            rst writeLine(".. enumElement:: %s" format(member name))
            if(member doc != null) {
                rst indent()
                rst writeLine(formatDoc(member doc))
                rst writeLine("")
                rst dedent()
            }
        }
        rst dedent()
    }
}

SphinxRSTBackend: class extends Backend {
    outPath: File

    init: func ~derived (=repo) {
        outPath = repo root getChild("out")
        outPath mkdirs()
    }

    handleModule: func (module: SModule) {
        if(module path != null && !module path empty?()) {
            ("Handling module " + module name + ".") println() 
            file := outPath getChild(module path + ".rst") /* TODO: does this work in all cases? */
            file parent() mkdirs()
            rst := RSTWriter new(FileWriter new(file))
            visitor := RSTVisitor new(rst)
            /* headline & .. module directive. */
            rst writeLine(module path) \
               .writeLine("=" times(module path length())) \
               .writeLine("") \
               .writeLine(".. module:: %s" format(module path)) \
               .writeLine("")
            visitor visitChildren(module)
            rst close()
            ("Module " + module name + " handled.") println()
        }
    }

    run: func {
        modules := repo getModules()
        for(key in modules getKeys()) {
            handleModule(modules[key])
        }
    }
}
