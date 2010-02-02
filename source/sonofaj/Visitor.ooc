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
        match node type {
            case "function" => { visitFunction(node) }
            case "class" => { visitClass(node) }
            case "cover" => { visitCover(node) }
            case "globalVariable" => { visitGlobalVariable(node) }
        }
    }
}
