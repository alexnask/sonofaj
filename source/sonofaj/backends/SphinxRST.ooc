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
                newLine println()
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

    visitFunction: func (node: SFunction) {
        rst writeLine(".. function:: %s" format(node getSignature()))
        rst indent()
        rst writeLine("")
        if(node doc != null) {
            rst writeLine(formatDoc(node doc))
        }
        rst dedent()
    }
    visitClass: func (node: SClass) {
        rst writeLine(".. class:: %s" format(node name))
    }
    visitCover: func (node: SCover) {}
    visitGlobalVariable: func (node: SGlobalVariable) {}
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
        visitor visitChildren(module)
        rst close()
    }

    run: func {
        for(module: SModule in repo getModules()) {
            handleModule(module)
        }
    }
}
