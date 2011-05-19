import sonofaj/Nodes

Visitor: abstract class {
    visitFunction: abstract func (node: SFunction)
    visitClass: abstract func (node: SClass)
    visitCover: abstract func (node: SCover)
    visitGlobalVariable: abstract func (node: SGlobalVariable)
    
    visitChildren: func (node: SModule) {
        for(child: SNode in node children) {
            visit(child)
        }
    }

    visit: func (node: SNode) {
        match (node type) {
            case "function" => { visitFunction(node as SFunction) }
            case "class" => { visitClass(node as SClass) }
            case "cover" => { visitCover(node as SCover) }
            case "globalVariable" => { visitGlobalVariable(node as SGlobalVariable) }
            case => "WTF? '%s' has type '%s' which is unknown." format(node name, node type) println()
        }
    }
}
