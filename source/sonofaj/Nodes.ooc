import structs/[ArrayList, HashMap, HashBag, Bag]
import text/StringTokenizer

import sonofaj/[Repository, Tag]


// TODO:Interfaces
// TODO:Named imports


readStringList: func (list: Bag) -> ArrayList<String> {
    ret := ArrayList<String> new()
    for(i: SizeT in 0..list size) {
        if(list getClass(i) != String) {
            JSONException new("Expected string, got %d" format(list getClass(i) name)) throw()
        }
        ret add(list get(i, String))
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
    read: abstract func <T> (value: T)

    getIdentifier: func -> String {
        name
    }

    getBaseType: func (type: String) -> String {
        tag := Tag parse(type)
        while(true) {
            if(tag hasArguments() && tag value != "Func") {
                if(tag value == "multi") {
                    // Tuple
                    ret := "("
                    for(arg in tag arguments) {
                        ret += formatTypeRef(arg toString())
                        if(tag arguments indexOf(arg) != tag arguments getSize() - 1) {
                            ret += ','
                        }
                    }
                    ret += ")"
                    return ret
                }
                tag = tag arguments get(0)
            } else if(!tag hasArguments()) {
                // get the type identifier
                return getTypeIdentifier(tag value)
            } else {
                // Func types
                ret := "Func"
                for(targ in tag arguments) {
                    if(targ value == "arguments") {
                        ret += "("
                        for(arg in targ arguments) {
                            ret += formatTypeRef(arg toString())
                            if(targ arguments indexOf(arg) != targ arguments getSize() - 1) {
                                ret += ','
                            }
                        }
                        ret += ")"
                    } else if(targ value == "return") {
                        ret += " -> " + formatTypeRef(targ arguments[0] value)
                    } else if(targ value == "multi") {
                        // Tuple return type
                        ret += " -> ("
                        for(arg in targ arguments) {
                            ret += formatTypeRef(arg toString())
                            if(targ arguments indexOf(arg) != targ arguments getSize() - 1) {
                                ret += ','
                            }
                        }
                        ret += ")"
                    }
                }
                return ret
            }
        }
        ""
    }

    getSuffixes: static func (type: String) -> String {
        tag := Tag parse(type)
        suffixes := ""
        while(true) {
            if(tag hasArguments()) {
                if(tag value == "pointer") {
                    suffixes = suffixes append('*')
                } else if(tag value == "reference") {
                    suffixes = suffixes append('@')
                }
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

    createNode: func <T> (entity: T) -> This {
        value := (entity as HashBag) get("type", String)
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
                if(arg name endsWith?("_generic") || genericTypes contains?(arg type)) {
                    // The _generic thingy is a quick and dirty way that works for some functions, because in json genericTypes not alway full
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
            if(genericTypes contains?(returnType)) {
                buf append(" -> " + returnType)
            } else if(ref) {
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

    read: func <T> (value: T) {
        entity := value as HashBag
        // name
        name = entity get("name", String)
        name = name replaceAll("__quest","?")
        // modifiers
        modifiers = readStringList(entity get("modifiers", Bag))
        // genericTypes
        genericTypes = readStringList(entity get("genericTypes", Bag))
        // extern
        if(entity getClass("extern") == Bool) {
            extern_ = entity get("extern", Bool)
        } else {
            "Ignoring extern name: %s (TODO)" printfln(name)
        }
        // returnType
        if(entity getClass("returnType") == Pointer) {
            returnType = null
        } else {
            returnType = entity get("returnType", String)
        }
        
        // unmangled
        unmangled_ = entity get("unmangled", Bool)
        // fullName
        fullName = entity get("fullName", String)
        // doc
        if(entity getClass("doc") == Pointer) {
            doc = null
        } else {
            doc = entity get("doc", String) // can also be null
        }
        // arguments
        arguments = ArrayList<SArgument> new()
        argumentsList := entity get("arguments", Bag)
        for(i: SizeT in 0..argumentsList size) {
            argumentsObject := argumentsList get(i, Bag)
            argument := SArgument new()
            argument name = argumentsObject get(0, String)
            argument type = argumentsObject get(1, String)
            _blah := argumentsObject get(2, Bag)
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

    read: func <T> (value: T) {
        entity := value as HashBag
        // name
        name = entity get("name", String)
        name = name replaceAll("__quest","?")
        // modifiers
        modifiers = readStringList(entity get("modifiers", Bag))
        // value
        if(entity getClass("value") == Pointer) {
            this value = null
        } else {
            this value = entity get("value", String)
        }
        // varType
        varType = entity get("varType", String)
        // extern
        if(entity getClass("extern") == Bool) {
            extern_ = entity get("extern", Bool)
        } else {
            "Ignoring extern name: %s (TODO)" printfln(name)
        }
        // unmangled; dirty workaround since j/ooc has problems with decls inside of version blocks not considered global; and even dirtier now.
        unmangled_ = entity get("unmangled", Bool)
        // fullName
        fullName = entity get("fullName", String)
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

    read: func <T> (value: T) {
        entity := value as HashBag
        // name
        name = entity get("name", String)
        // modifiers
        modifiers = readStringList(entity get("modifiers", Bag))
        // value
        if(entity getClass("value") == Pointer) {
            this value = null
        } else {
            this value = entity get("value", String)
        }
        // varType
        varType = entity get("varType", String)
        // extern
        if(entity getClass("extern") == Bool) {
            extern_ = entity get("extern", Bool)
        } else {
            "Ignoring extern name: %s (TODO)" printfln(name)
        }
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
        ":class:`~%s %s`" format(module getIdentifier(), getIdentifier(false))
    }

    getExtendsRef: func -> String {
        if(extends_ != null)
            return formatTypeRef(extends_)
        else
            return null
    }

    read: func <T> (value: T) {
        entity := value as HashBag
        // name
        name = entity get("name", String)
        name = name replaceAll("__quest","?")
        // genericTypes
        genericTypes = readStringList(entity get("genericTypes", Bag))
        // extends
        if(entity getClass("extends") == Pointer) {
            extends_ = null
        } else {
            extends_ = entity get("extends", String) // can also be null
        }
        // abstract
        abstract_ = entity get("abstract", Bool)
        // fullName
        fullName = entity get("fullName", String)
        // doc
        if(entity getClass("doc") == Pointer) {
            doc = null
        } else {
            doc = entity get("doc", String) // can also be null
        }
        // members
        members = ArrayList<SMember> new()
        membersList := entity get("members", Bag)
        for(i: SizeT in 0..membersList size) {
            membersObject := membersList get(i, Bag)
            member := SMember new()
            member name = membersObject get(0, String)
            node := createNode(membersObject get(1, HashBag))
            member node = node
            members add(member)
        }
    }

    getIdentifier: func ~genericTypes (withGenericTypes: Bool) -> String {
        if(withGenericTypes && !genericTypes empty?()) {
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

    getIdentifier: func -> String {
        getIdentifier(true)
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

    read: func <T> (value: T) {
        entity := value as HashBag
        // name
        name = entity get("name", String)
        name = name replaceAll("__quest","?")
        // fullName
        fullName = entity get("fullName", String)
        // extends
        if(entity getClass("extends") == Pointer) {
            extends_ = null
        } else {
            extends_ = entity get("extends", String)
        }
        // from
        if(entity getClass("from") == Pointer) {
            from_ = null
        } else {
            from_ = entity get("from", String)
        }
        // doc
        if(entity getClass("doc") == Pointer) {
            doc = null
        } else {
            doc = entity get("doc", String) // can also be null
        }
        // members
        members = ArrayList<SMember> new()
        membersList := entity get("members", Bag)
        for(i: SizeT in 0..membersList size) {
            membersObject := membersList get(i, Bag)
            member := SMember new()
            member name = membersObject get(0, String)
            node := createNode(membersObject get(1, HashBag))
            member node = node
            members add(member)
        }
    }
}

// TODO: Add Interfaces
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

    read: func <T> (value: T) {
        entity := value as HashBag
        // name
        name = entity get("name", String)
        name = name replaceAll("__quest","?")
        // extern
        if(entity getClass("extern") == Bool) {
            extern_ = entity get("extern", Bool)
        } else {
            "Ignoring extern name: %s (TODO)" printfln(name)
        }
        // doc
        if(entity getClass("doc") == Pointer) {
            doc = null
        } else {
            doc = entity get("doc", String) // can also be null
        }
        // members
        members = ArrayList<SMember> new()
        membersList := entity get("elements", Bag)
        for(i: SizeT in 0..membersList size) {
            membersObject := membersList get(i, Bag)
            member := SEnumElement new()
            member name = membersObject get(0, String)
            member doc = membersObject get(1, HashBag) get("doc",String)
            members add(member)
        }
    }
}


SAnyType : class extends SType {
    init : func (=repo, =parent, =module)
    
    getRef : func -> String {
        name
    }
    
    read: func <T> (value: T)
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

    createChild: func <T> (entity: T) {
        node := createNode(entity)
        if(node != null) /* happens for the `module` node */
            addNode(node)
    }

    addNode: func (node: SNode) {
        children[node name] = node
    }
    
    read: func <T> (value: T) {
        // We want the entities
        if(T == HashBag) {
            map := value as HashBag
            readModule(value)
            if(map getClass("entities") == Bag) {
                entities := map get("entities", Bag)
                if(entities != null) {
                    for(i: SizeT in 0..entities size) {
                        // Get all entities and read them
                        if(entities getClass(i) == Bag) {
                            createChild(entities get(i, Bag) get(1, HashBag))
                        }
                    }
                }
            }
        }
    }

    readModule: func <T> (value: T) {
        entity := value as HashBag
        if(entity getClass("globalImports") == Bag) {
            imports = readStringList(entity get("globalImports", Bag))
            // TODO: Manage namespaced imports
        }
        if(entity getClass("path") == String) {
            path = entity get("path", String)
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

    resolveName: func (name: String, searchImported: Bool, level := 1) -> SNode {
        // strip generic definitions
        if(name contains?('<'))
            name = name substring(0, name indexOf('<'))
        // All func types start with Func
        if(name startsWith?("Func")) {
            f := SAnyType new(repo, parent, this)
            f name = name
            return f
        }
        // Check for tuples
        if(name startsWith?("(") && name endsWith?(")")) {
            t := SAnyType new(repo, parent, this)
            t name = name
            return t
        }
        // VarArgs
        if(name == "...") {
            v := SAnyType new(repo, parent, this)
            v name = "VarArgs"
            return v
        }
        /* TODO: do that with exceptions. */
        for(node in children) {
            if(node name == name) {
                return node
            } else if(node type == "class") {
                if(node as SClass genericTypes contains?(name)) {
                    // Class generics
                    // TODO: Improve this :/
                    // The usage of SAnyType here avoids certain bugs where the class that contained the type was returned
                    // and not the type itself
                    t := SAnyType new(repo, parent, this)
                    t name = name
                    return t
                }
            }
        }
        // look in imported modules if `searchImported` is true.
        if(searchImported && level < 3) {
            for(importedName in imports) {
                importedModule := repo getModule(resolveModule(importedName))
                node := importedModule resolveName(name, true, level+1) // do not walk into imported modules here.
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

