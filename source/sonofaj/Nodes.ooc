import structs/[ArrayList, HashMap, HashBag]
import text/StringTokenizer

use yajl

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


JSONException: class extends Exception {
    init: func ~withMsg (msg: String) {
        super(msg)
    }
}

TypeException: class extends Exception {
    init: func ~withMsg (msg: String) {
        super(msg)
    }
}

SNode: abstract class {
    repo: Repository
    module: SModule
    name, type: String
    parent: SNode

    init: func (=repo, =parent, =module)
    read: abstract func (value: Value<Pointer>)

    getIdentifier: func -> String {
        name
    }

    getBaseType: func (type: String) -> String {
        tag := Tag parse(type)
        while(true) {
            if(tag hasArguments()) {
                tag = tag arguments get(0)
            } else {
                // get the type identifier
                return getTypeIdentifier(tag value)
            }
        }
        ""
    }

    getSuffixes: static func (type: String) -> String {
        tag := Tag parse(type)
        suffixes := ""
        while(true) {
            if(tag hasArguments()) {
                suffixes = suffixes append(match (tag value) {
                    case "pointer" => '*'
                    case "reference" => '@'
                    case => '?' /* TODO */
                })
                tag = tag arguments get(0)
            } else {
                // get the type identifier
                return suffixes
            }
        }
        ""
    }

    formatTypeRef: func (type: String) -> String {
        base := getBaseType(type)
        suffixes := getSuffixes(type)
        getTypeRef(base) + ' ' + suffixes
    }

    formatType: func (type: String) -> String {
        tag := Tag parse(type)
        suffixes := ""
        while(true) {
            if(tag hasArguments()) {
                suffixes = suffixes append(match (tag value) {
                    case "pointer" => '*'
                    case "reference" => '@'
                    case => '?' /* TODO */
                })
                tag = tag arguments get(0)
            } else {
                // get the type identifier
                return getTypeIdentifier(tag value) + suffixes
            }
        }
        ""
    }

    getTypeIdentifier: func (name: String) -> String {
        module resolveType(name) getIdentifier()
    }

    getTypeRef: func (name: String) -> String {
        module resolveType(name) getRef()
    }

    getRef: abstract func -> String

    createNode: func (entity: Value<Pointer>) -> This {
        value := (entity value as ValueMap)["type", String]
        match (value) {
            case "method" => {
                node := SMethod new(repo, this, module)
                node read(entity)
                return node
            }
            case "class" => {
                node := SClass new(repo, this, module)
                node read(entity)
                return node
            }
            case "cover" => {
                node := SCover new(repo, this, module)
                node read(entity)
                return node
            }
            case "enum" => {
                node := SEnum new(repo, this, module)
                node read(entity)
                return node
            }
            case "function" => {
                node := SFunction new(repo, this, module)
                node read(entity)
                return node
            }
            case "globalVariable" => {
                node := SGlobalVariable new(repo, this, module)
                node read(entity)
                return node
            }
            case "field" => {
                node := SField new(repo, this, module)
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
    init: func (=repo, =parent, =module)
    getIdentifier: func -> String {
        name
    }
}

SFuncType: class extends SType {
    init: func ~rhabarberbarbarabarbarbarenbarbierbierbar (=repo, =parent, =module) {
        type = "!func"
        name = "Func"
    }

    getRef: func -> String {
        name
    }

    read: func (value: Value<Pointer>)
}

SVarArgsType: class extends SType {
    // Thank you fred for inspiring me that name from the ones you use =D
    init : func ~bubaaaaaaaaaaaaaaaaaaaaaaaaaaaaa (=repo, =parent, =module) {
        type = "VarArgs"
        name = "..."
    }
    
    getRef : func -> String {
        name
    }
    
    read: func (value : Value<Pointer>)
}

SArgument: class {
    name, type: String
    modifiers: ArrayList<String> // might be empty.
}

SFunction: class extends SNode {
    returnType, doc,  fullName: String
    extern_, unmangled_ : Bool
    modifiers, genericTypes: ArrayList<String>
    arguments: ArrayList<SArgument>

    init: func ~urgh(=repo, =parent, =module) {
        type = "function"
    }

    getRef: func -> String {
        ":func:`~%s %s`" format(module getIdentifier(), getIdentifier())
    }

    hasModifier: func (mod: String) -> Bool {
        for(having in modifiers)
            if(having == mod)
                return true
        return false
    }

    getTypeIdentifier: func (name: String) -> String {
        // generic type? 
        for(gen in genericTypes)
            if(gen == name)
                return name
        // no? :(
        return module resolveType(name) getIdentifier()
    }

    getTypeRef: func (name: String) -> String {
        // generic type? 
        for(gen in genericTypes)
            if(gen == name)
                return name
        // no? :(
        return module resolveType(name) getRef()
    }

    getSignature: func (ref: Bool) -> String {
        /* "$name~suffix $arguments -> $returntype */
        buf := Buffer new()
        // name
        buf append(name) 
        if(!arguments empty?() && arguments != null) {
            // arguments
            buf append(" (")
            first := true
            for(idx in 0..arguments getSize()) {
                arg := arguments[idx]
                // comma?
                if(first)
                    first = false
                else
                    buf append(", ")
                // name
                if(!arg name empty?())
                    buf append(arg name)
                // check if we can group args
                if(!arg name empty?())
                    if(idx < arguments getSize() - 1)
                        if(arg type == arguments[idx + 1] type) // same type?
                            if(arg modifiers empty?()) // no modifiers?
                                if(arguments[idx + 1] modifiers empty?()) {
                                    // yeah, we can group!
                                    continue
                                }
                // nope. write type.
                if(!arg name empty?())
                    buf append(": ")
                if(arg name endsWith?("_generic")) {
                    // Quick and dirty way, but in json genericTypes is always empty :(
                    buf append(arg type)
                } else if(ref) {
                    buf append(formatTypeRef(arg type))
                } else {
                    buf append(formatType(arg type))
                }
            }
            buf append(')')
        }
        if(returnType != null) {
            if(ref) {
                buf append(" -> %s" format(formatTypeRef(returnType)))
            } else {
                buf append(" -> %s" format(formatType(returnType)))
            }
        }
        return buf toString()
    }

    getSignature: func ~noRef -> String {
        getSignature(false)
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
        extern_ = entity["extern", Bool]
        // returnType
        returnType = entity["returnType", String] // can also be null
        
        // unmangled
        unmangled_ = entity["unmangled", Bool]
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

SMethod: class extends SFunction {
    init: func ~bringtomiopiopiumbringtopiumdenopium (=repo, =parent, =module) {
        type = "method"
    }

    getRef: func -> String {
        ":mfunc:`~%s %s %s`" format(module getIdentifier(), parent getIdentifier(), getIdentifier())
    }

    getTypeIdentifier: func (name: String) -> String {
        // generic type? 
        for(gen in genericTypes)
            if(gen == name)
                return name
        // generic type of my class?
        if(parent instanceOf?(SClass))
            for(gen in parent as SClass genericTypes)
                if(gen == name)
                    return name
        // no? :(
        return module resolveType(name) getIdentifier()
    }

    getTypeRef: func (name: String) -> String {
        // generic type? 
        for(gen in genericTypes)
            if(gen == name)
                return name
        // generic type of my class?
        if(parent instanceOf?(SClass))
            for(gen in parent as SClass genericTypes)
                if(gen == name)
                    return name
        // no? :(
        return module resolveType(name) getRef()
    }
}

SGlobalVariable: class extends SNode {
    modifiers: ArrayList<String>
    value, varType, fullName: String
    extern_, unmangled_ : Bool

    init: func ~dadadadam (=repo, =parent, =module) {
        type = "globalVariable"
    }

    getRef: func -> String {
        ":var:`~%s %s`" format(module getIdentifier(), getIdentifier())
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
        extern_ = entity["extern", Bool]
        // unmangled; dirty workaround since j/ooc has problems with decls inside of version blocks not considered global; and even dirtier now.
        unmangled_ = entity["unmangled", Bool]
        // fullName
        fullName = entity["fullName", String]
    }

    getTypeIdentifier: func ~my -> String {
        formatType(varType)
    }

    getTypeRef: func ~my -> String {
        formatTypeRef(varType)
    }
}

SField: class extends SGlobalVariable {
    init: func ~HURZ (=repo, =parent, =module) {
        type = "field"
    }

    getRef: func -> String {
        ":field:`~%s %s %s`" format(module getIdentifier(), parent getIdentifier(), getIdentifier())
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
        extern_ = entity["extern", Bool]
    }

    getTypeIdentifier: func ~my -> String {
        return formatType(varType)
    }

    getTypeRef: func ~my -> String {
        formatTypeRef(varType)
    }

    getTypeIdentifier: func (name: String) -> String {
        // generic type of my class?
        if(parent instanceOf?(SClass))
            for(gen in parent as SClass genericTypes)
                if(gen == name)
                    return name
        // no? :(
        return module resolveType(name) getIdentifier()
    }

    getTypeRef: func (name: String) -> String {
        // generic type of my class?
        if(parent instanceOf?(SClass))
            for(gen in parent as SClass genericTypes)
                if(gen == name)
                    return name
        // no? :(
        return module resolveType(name) getRef()
    }
}

SMember: class {
    name: String
    node: SNode
}

SClass: class extends SType {
    genericTypes: ArrayList<String>
    members: ArrayList<SMember>
    extends_, doc, fullName: String
    abstract_: Bool

    init: func ~wurst (=repo, =parent, =module) {
        type = "class"
    }

    getRef: func -> String {
        ":class:`~%s %s`" format(module getIdentifier(), getIdentifier())
    }

    getExtendsRef: func -> String {
        if(extends_ != null)
            return formatTypeRef(extends_)
        else
            return null
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

    getIdentifier: func -> String {
        if(!genericTypes empty?()) {
            buf := Buffer new()
            buf append(name) .append('<')
            first := true
            for(type_ in genericTypes) {
                if(first)
                    first = false
                else
                    buf append(",")
                buf append(type_)
            }
            buf append('>')
            return buf toString()
        } else {
            return name
        }
    }
}

SCover: class extends SType {
    members: ArrayList<SMember>
    extends_, doc, from_, fullName: String

    init: func ~krautsalat_dasistdochmeinlieblingsessen (=repo, =parent, =module) {
        type = "cover"
    }

    getExtendsRef: func -> String {
        if(extends_ != null)
            return formatTypeRef(extends_)
        else
            return null
    }

    getRef: func -> String {
        ":cover:`~%s %s`" format(module getIdentifier(), getIdentifier())
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // fullName
        fullName = entity["fullName", String]
        // extends
        extends_ = entity["extends", String] // can also be null
        // from
        from_ = entity["from", String]
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

// TODO: Add Interfaces
// TODO: Add enums
SEnumElement : class {
    name : String
    doc : String
}

SEnum : class extends SType {
    members: ArrayList<SEnumElement>
    extern_: Bool
    doc: String
    
    init: func ~naimilasgermanika_egomilaoellinika (=repo, =parent, =module) {
        type = "enum"
    }

    getRef: func -> String {
        ":enum:`~%s %s`" format(module getIdentifier(), getIdentifier())
    }

    read: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        // name
        name = entity["name", String]
        // extern
        extern_ = entity["extern", Bool]
        // doc
        doc = entity["doc", String] // can also be null
        // members
        members = ArrayList<SMember> new()
        membersList := entity["elements", ValueList]
        for(membersValue: Value<ValueList> in membersList) {
            membersObject := membersValue value as ValueList
            member := SEnumElement new()
            member name = membersObject[0, String]
            member doc = membersObject[1, ValueMap]["doc",String]
            members add(member)
        }
    }
}

SModule: class extends SNode {
    children := HashMap<String, SNode> new()
    imports := ArrayList<String> new()
    path: String

    init: func ~hihi(=repo, =parent, =module) {
        type = "module"
    }

    init: func ~lazy(=repo) {
        init(repo, null, this)
    }

    getRef: func -> String {
        ":mod:`~%s`" format(getIdentifier())
    }

    createChild: func (entity: Value<Pointer>) {
        node := createNode(entity)
        if(node != null) /* happens for the `module` node */
            addNode(node)
    }

    addNode: func (node: SNode) {
        children[node name] = node
    }
    
    read: func (value: Value<Pointer>) {
        // We want the entities
        if(value type == ValueMap) {
            map := value value as ValueMap
            readModule(value)
            if(map getType("entities") == ValueList) {
                entities := map["entities",ValueList]
                if(entities != null) {
                    for(entity in entities) {
                        // Get all entities and read them
                        if(entity != null) {
                            if(entity type == ValueList) {
                                createChild(entity value as ValueList get(1))
                            }
                        }
                    }
                }
            }
        }
    }

    readModule: func (value: Value<Pointer>) {
        entity := value value as ValueMap
        if(entity getType("globalImports") == ValueList) {
            imports = readStringList(entity["globalImports", ValueList])
            // TODO: Manage namespaced imports
        }
        if(entity getType("path") == String) {
            path = entity["path", String]
            name = path
        }
    }

    resolveModule: func (name: String) -> String {
        if(name contains?("..")) {
            /* relative path ... */
            pathSplitted := path split('/')
            pathSplitted removeLast()
            while(name startsWith?("../")) {
                pathSplitted removeLast()
                name = name substring(3)
            }
            pathSplitted add(name)
            return pathSplitted join('/')
        } else if(path contains?('/')) {
            testPathArr := [this path substring(0, this path indexOf('/')), name] as ArrayList<String>
            testPath := testPathArr join('/')
            if(repo getModuleFilenameNoCry(testPath) != null)
                return testPath
        }
        return name
    }

    resolveName: func (name: String, searchImported: Bool) -> SNode {
        // strip generic definitions
        if(name contains?('<'))
            name = name substring(0, name indexOf('<'))
        // All func types start with Func
        if(name startsWith?("Func")) {
            f := SFuncType new(repo, parent, this)
            f name = name
            return f
        }
        // VarArgs
        if(name == "..." || name == "VarArgs") {
            return SVarArgsType new(repo, parent, this)
        }
        /* TODO: do that with exceptions. */
        for(node in children) {
            if(node name == name) {
                return node
            }
        }
        // look in imported modules if `searchImported` is true.
        if(searchImported) {
            for(importedName in imports) {
                importedModule := repo getModule(resolveModule(importedName))
                node := importedModule resolveName(name, false) // do not walk into imported modules here.
                if(node != null)
                    return node
            }
        }
        return null
    }

    resolveName: func ~entry (name: String) -> SNode {
        resolveName(name, true)
    }

    resolveType: func (name: String) -> SType {
        node := resolveName(name)
        if(!node || !node instanceOf?(SType))
            TypeException new(This, "Couldn't resolve type: '%s' in '%s'" format(name, path)) throw()
        return node as SType
    }
}

