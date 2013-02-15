import sonofaj/Nodes

Visitor: abstract class {
    visitFunction: abstract func (node: SFunction)
    visitClass: abstract func (node: SClass)
    visitCover: abstract func (node: SCover)
    visitEnum: abstract func (node : SEnum)
    visitGlobalVariable: abstract func (node: SGlobalVariable)
    
    visitChildren: func (node: SModule) {
        for(child: SNode in node children) {
            visit(child)
        }
    }

    visit: func (node: SNode) {
        // We ignore all private stuff (names starting with _)
        if(!node name startsWith?('_')) match (node type) {
            case "function" => { visitFunction(node as SFunction) }
            case "class" => { visitClass(node as SClass) }
            case "cover" => { visitCover(node as SCover) }
            case "globalVariable" => { visitGlobalVariable(node as SGlobalVariable) }
            case "enum" => { visitEnum(node as SEnum) }
            case => "WTF? '%s' has type '%s' which is unknown." format(node name, node type) println()
        }
    }
}
