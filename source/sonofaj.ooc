use optparse

import io/[File, FileReader]
import structs/[HashBag, Bag, ArrayList]

import optparse/[Parser, Option]

import sonofaj/[Nodes, Repository]
import sonofaj/backends/[SphinxRST,Html]

setupParser: func -> Parser {
    parser := Parser new()
    
    backend := StringOption new("backend") .shortName("b") .longName("backend") \
              .help("Specify the sonofaj backend. Possible: sphinx, html") .metaVar("NAME")
    repo := StringOption new("repo") .shortName("r") .longName("repo") \
           .help("Specify the repository.") .metaVar("DIR")
    package := StringOption new("package") .shortName("p") .longName("package") \
              .help("Specify the package (currently unusable).") .metaVar("DIR")
    ooc := StringOption new("ooc") .shortName("c") .longName("ooc") \
          .help("Specify the compiler path.") .metaVar("OOC") .defaultValue("ooc") // TODO: CROSS PLATFORM ALARM
    
    parser addOption(backend) .addOption(repo) .addOption(package) .addOption(ooc)

    parser
}

main: func (args: ArrayList<String>) {
    parser := setupParser()

    if(args getSize() == 1) {
        parser displayHelp()
    } else {
        parser parse(args)
        
        if(parser values get("backend", String) empty?()) {
            parser error("You have to specify a backend.")
        }

        hasRepo := !parser values get("repo", String) empty?()
        hasPackage := !parser values get("package", String) empty?()

        /* check if there was a repo OR a package specified. */
        if(!((hasRepo && !hasPackage) || (hasPackage && !hasRepo))) {
            parser error("You have to specify either a repo or a package.")
        }
        
        repo := Repository new(File new(parser values get("repo", String)))
        repo getAllModules()
        "Modules loaded. Starting backend." println()
        match (parser values get("backend", String)) {
            case "sphinx" => {
                backend := SphinxRSTBackend new(repo)
                backend run()
                "Done." println()
            }
            case "html" => {
                backend := HtmlBackend new(repo)
                backend run()
                "Done." println()
            }
            case => {
                parser error("Available backends: sphinx, html")
            }
        }
    }
}
