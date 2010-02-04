import io/[File, FileWriter, Writer]
import text/StringTokenizer
import structs/ArrayList

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
        indentString = "    " * indentLevel
    }

    indent: func {
        resetIndent(indentLevel + 1)
    }

    dedent: func {
        resetIndent(indentLevel - 1)
    }

    writeLine: func (line: String) {
        if(line contains('\n')) {
            for(newLine in line split('\n') toArrayList()) {
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
        rst writeLine(".. %s:: %s" format(directive, node getSignature()))
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
        rst writeLine(".. %s:: %s" format(directive, node name)) .writeLine("")
    }

    visitGlobalVariable: func (node: SGlobalVariable) {
        visitGlobalVariable(node, "globalVariable")
    }

    visitClass: func (node: SClass) {
        rst writeLine(".. class:: %s" format(node getIdentifier()))
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
            match member node type {
                case "memberFunction" => {
                    visitFunction(member node, "memberfunction")
                }
                case "field" => {
                    visitGlobalVariable(member node, "field")
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
        // doc
        if(node doc != null) {
            rst writeLine(formatDoc(node doc))
            rst writeLine("")
        }
        // members.
        for(member in node members) {
            match member node type {
                case "memberFunction" => {
                    visitFunction(member node, "memberfunction")
                }
                case "field" => {
                    visitGlobalVariable(member node, "field")
                }
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
        file := outPath getChild(module path + ".rst") /* TODO: does this work in all cases? */
        file parent() mkdirs()
        rst := RSTWriter new(FileWriter new(file))
        visitor := RSTVisitor new(rst)
        /* headline & .. module directive. */
        rst writeLine(module path) \
           .writeLine("=" * module path length()) \
           .writeLine("") \
           .writeLine(".. module:: %s" format(module path)) \
           .writeLine("")
        visitor visitChildren(module)
        rst close()
    }

    run: func {
        for(module: SModule in repo getModules()) {
            handleModule(module)
        }
    }
}
