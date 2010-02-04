use yajl

import io/[File, FileReader]
import structs/[ArrayList, HashMap]
import text/StringTokenizer

import yajl/Yajl

import sonofaj/Nodes

ModuleNotFoundException: class extends Exception {
    init: func ~withMsg (msg: String) {
        super(msg)
    }
}

Repository: class {
    root: File
    cache: HashMap<SModule>

    init: func (=root) {
        cache = HashMap<SModule> new()
    }

    getModule: func (module: String) -> SModule {
        if(!cache contains(module))
            cache[module] = loadModule(module)
        cache[module]
    }

    getModules: func -> HashMap<SModule> {
        cache
    }

    loadModule: func (module: String) -> SModule {
        reader := FileReader new(getModuleFilename(module))
        parser := SimpleParser new()
        parser parseAll(reader)
        reader close()
        node := SModule new(this)
        node read(parser getValue())
        node
    }
    
    getModuleFilename: func (module: String) -> String {
        parts := module split('/') toArrayList()
        lastIndex := parts lastIndex()
        parts[lastIndex] = parts[lastIndex] append(".json")
        path := parts join(File separator)
        for(subdir: File in root getChildren()) {
            if(subdir isDir() && subdir getChild(path) exists()) {
                return subdir getChild(path) path
            }
        }
        ModuleNotFoundException new(This, "Module not found: %s" format(module)) throw()
        null
    }

    getModuleFilenames: func ~entry -> ArrayList<String> {
        names := ArrayList<String> new()
        for(dir in root getChildren())
            names addAll(getModuleFilenames(dir))
        names
    }

    getModuleFilenames: func (dir: File) -> ArrayList<String> {
        // first, get all that we have here. Let's say "*.json" is a module.
        names := ArrayList<String> new()
        for(child in dir getChildren()) {
            if(child isFile() && child name() endsWith(".json")) {
                childName := child name()
                names add(childName substring(0, childName length() - 5))
            }
        }
        // now, get all subdirectories.
        for(child in dir getChildren()) {
            if(child isDir()) {
                childName := child name()
                for(name in getModuleFilenames(child)) {
                    names add("%s/%s" format(childName, name))
                }
            }
        }
        return names
    }

    getAllModules: func {
        for(name in getModuleFilenames())
            getModule(name)
    }
}
