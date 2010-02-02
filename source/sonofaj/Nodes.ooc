use yajl

import structs/[ArrayList, HashMap]

import yajl/Yajl

import sonofaj/Repository

readStringList: func (list: ValueList) -> ArrayList<String> {
    ret := ArrayList<String> new()
    for(value: Value<Pointer> in list) {
        if(value getType() != ValueType STRING) {
            JSONException new("Expected string, got %d" format(value getType())) throw()
        }
        ret add(value value as String)
    }
    ret
}

JSONException: class extends Exception {
    init: func ~withMsg (msg: String) {
        super(msg)
    }
}

SNode: abstract class {
    repo: Repository
    name, type: String
    parent: SNode

    init: func (=repo, =parent) {}
    read: abstract func (value: Value<Pointer>)

    createNode: func (entity: Value<Pointer>) -> This {
        value := (entity value as ValueMap)["type", String]
        match value {
            case "memberFunction" => {
                node := SMemberFunction new(repo, this)
                node read(entity)
                node
            }
            case "class" => {
                node := SClass new(repo, this)
                node read(entity)
                return node
            }
            case "cover" => {
                node := SCover new(repo, this)
                node read(entity)
                return node
            }
            case "function" => {
                node := SFunction new(repo, this)
                node read(entity)
                return node
            }
            case "globalVariable" => {
                node := SGlobalVariable new(repo, this)
                node read(entity)
                return node
            }
            case "field" => {
                node := SField new(repo, this)
                node read(entity)
                return node
            }
            case "module" => {
                (this as SModule) readModule(entity)
            }
        }
        null
    }
}


SType: abstract class extends SNode {

}

SArgument: class {
    name, type: String
    modifiers: ArrayList<String> // might be empty.
}

SFunction: class extends SNode {
    returnType, extern_, doc: String
    modifiers, genericTypes: ArrayList<String>
    arguments: ArrayList<SArgument>

    init: func ~urgh(=repo, =parent) {
        type = "function"
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // modifiers
        modifiers = readStringList(entity["modifiers", ValueList])
        // genericTypes
        genericTypes = readStringList(entity["genericTypes", ValueList])
        // extern
        extern_ = entity["extern", String] // can also be null
        // returnType
        returnType = entity["returnType", String] // can also be null
        // doc
        doc = entity["doc", String] // can also be null
        // arguments
        arguments = ArrayList<SArgument> new()
        argumentsList := entity["arguments", ValueList]
        for(argumentsValue: Value<ValueList> in argumentsList) {
            argumentsObject := argumentsValue value as ValueList
            argument := SArgument new()
            argument name = argumentsObject[0, String]
            argument type = argumentsObject[1, String]
            _blah := argumentsObject[2, ValueList]
            if(_blah != null) {
                argument modifiers = readStringList(_blah)
            } else {
                argument modifiers = ArrayList<String> new()
            }
            arguments add(argument)
        }
    }
}

SMemberFunction: class extends SFunction {
    init: func ~bringtomiopiopiumbringtopiumdenopium (=repo, =parent) {
        type = "memberFunction"
    }
}

SGlobalVariable: class extends SNode {
    modifiers: ArrayList<String>
    value, varType, extern_: String

    init: func ~dadadadam (=repo, =parent) {
        type = "globalVariable"
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // modifiers
        modifiers = readStringList(entity["modifiers", ValueList])
        // value
        this value = entity["value", String]
        // varType
        varType = entity["varType", String]
        // extern
        extern_ = entity["extern", String] // can also be null
    }
}

SField: class extends SGlobalVariable {
    init: func ~hihihihihi {
    }
}

SMember: class {
    name: String
    node: SNode
}

SClass: class extends SType {
    genericTypes: ArrayList<String>
    members: ArrayList<SMember>
    extends_, doc: String
    abstract_: Bool

    init: func ~wurst (=repo, =parent) {
        type = "class"
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // genericTypes
        //genericTypes = readStringList(entity["genericTypes", ValueList]) // we don't have it yet.
        // extends
        extends_ = entity["extends", String] // can also be null
        // abstract
        abstract_ = entity["abstract", Bool]
        // doc
        doc = entity["doc", String] // can also be null
        // members
        members = ArrayList<SMember> new()
        membersList := entity["members", ValueList]
        for(membersValue: Value<ValueList> in membersList) {
            membersObject := membersValue value as ValueList
            member := SMember new()
            member name = membersObject[0, String]
            node := createNode(membersObject get(1))
            member node = node
            members add(member)
        }
    }
}

SCover: class extends SType {
    members: ArrayList<SMember>
    extends_, doc, from_: String

    init: func ~krautsalat_dasistdochmeinlieblingsessen (=repo, =parent) {
        type = "cover"
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // genericTypes
        //genericTypes = readStringList(entity["genericTypes", ValueList]) // we don't have it yet.
        // extends
        extends_ = entity["extends", String] // can also be null
        // from
        from_ = entity["from", Bool]
        // doc
        doc = entity["doc", String] // can also be null
        // members
        members = ArrayList<SMember> new()
        membersList := entity["members", ValueList]
        for(membersValue: Value<ValueList> in membersList) {
            membersObject := membersValue value as ValueList
            member := SMember new()
            member name = membersObject[0, String]
            node := createNode(membersObject get(1))
            member node = node
            members add(member)
        }
    }
}

SModule: class extends SNode {
    children: HashMap<SNode>
    imports: ArrayList<String>

    init: func ~hihi(=repo, =parent) {
        type = "module"
        children = HashMap<SNode> new()
    }

    createChild: func (entity: Value<Pointer>) {
        node := createNode(entity)
        if(node != null) /* happens for the `module` node */
            addNode(node)
    }

    addNode: func (node: SNode) {
        children put(node name, node)
    }
    
    read: func (value: Value<Pointer>) {
        list := value value as ValueList
        for(entryValue: Value<Pointer> in list) {
            entry := entryValue value as ValueList
            entity := entry get(1)
            createChild(entity)
        }
    }

    readModule: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        imports = readStringList(entity["imports", ValueList])
    }
}
