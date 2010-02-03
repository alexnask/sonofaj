use yajl

import structs/[ArrayList, HashMap]
import text/StringBuffer

import yajl/Yajl

import sonofaj/[Repository, Tag]

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

formatType: func (type: String) -> String {
    tag := Tag parse(type)
    suffixes := ""
    while(true) {
        if(tag hasArguments()) {
            suffixes = suffixes append(match tag value {
                case "pointer" => '*'
                case "reference" => '@'
                case => '?' /* TODO */
            })
            tag = tag arguments get(0)
        } else {
            return tag value + suffixes
        }
    }
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
                return node
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
    returnType, extern_, doc, unmangled_, fullName: String
    modifiers, genericTypes: ArrayList<String>
    arguments: ArrayList<SArgument>

    init: func ~urgh(=repo, =parent) {
        type = "function"
    }

    getSignature: func -> String {
        /* "$name~suffix $arguments -> $returntype */
        buf := StringBuffer new()
        // name
        buf append(name) .append(' ')
        // arguments
        buf append('(')
        first := true
        for(idx in 0..arguments size()) {
            arg := arguments[idx]
            // comma?
            if(first)
                first = false
            else
                buf append(", ")
            // name
            buf append(arg name)
            // check if we can group args
            if(idx < arguments size() - 1)
                if(arg type == arguments[idx + 1] type) // same type?
                    if(arg modifiers isEmpty()) // no modifiers?
                        if(arguments[idx + 1] modifiers isEmpty()) {
                            // yeah, we can group!
                            buf append(", ")
                            continue
                        }
            // nope. write type.
            buf append(": ") .append(formatType(arg type))
        }
        buf append(')')
        if(returnType != null)
            buf append(" -> %s" format(formatType(returnType)))
        return buf toString()
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
        // unmangled
        unmangled_ = entity["unmangled", String] // can also be null
        // fullName
        fullName = entity["fullName", String]
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
    value, varType, extern_, unmangled_, fullName: String

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
        // unmangled
        unmangled_ = entity["unmangled", String] // can also be null
        // fullName
        fullName = entity["fullName", String]
    }
}

SField: class extends SGlobalVariable {
    modifiers: ArrayList<String>
    value, varType, extern_: String

    init: func ~dadadadam (=repo, =parent) {
        type = "field"
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

SMember: class {
    name: String
    node: SNode
}

SClass: class extends SType {
    genericTypes: ArrayList<String>
    members: ArrayList<SMember>
    extends_, doc, unmangled_, fullName: String
    abstract_: Bool

    init: func ~wurst (=repo, =parent) {
        type = "class"
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // genericTypes
        genericTypes = readStringList(entity["genericTypes", ValueList])
        // extends
        extends_ = entity["extends", String] // can also be null
        // abstract
        abstract_ = entity["abstract", Bool]
        // unmangled_
        unmangled_ = entity["unmangled", String] // can also be null
        // fullName
        fullName = entity["fullName", String]
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
    extends_, doc, from_, unmangled_, fullName: String

    init: func ~krautsalat_dasistdochmeinlieblingsessen (=repo, =parent) {
        type = "cover"
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // unmangled
        unmangled_ = entity["unmangled", String] // can also be null
        // fullName
        fullName = entity["fullName", String]
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
    path: String

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
        path = entity["path", String]
    }
}
