use optparse

import io/[File, FileReader]
import structs/[HashBag, Bag, ArrayList]

import optparse/[Parser, Option] into optparse

import sonofaj/[Nodes, Repository]
import sonofaj/backends/SphinxRST

setupParser: func -> optparse Parser {
    parser := optparse Parser new()
    
    backend := optparse StringOption new("backend") .shortName("b") .longName("backend") \
              .help("Specify the sonofaj backend. Possible: sphinx") .metaVar("NAME")
    repo := optparse StringOption new("repo") .shortName("r") .longName("repo") \
           .help("Specify the repository.") .metaVar("DIR")
    package := optparse StringOption new("package") .shortName("p") .longName("package") \
              .help("Specify the package (currently unusable).") .metaVar("DIR")
    ooc := optparse StringOption new("ooc") .shortName("c") .longName("ooc") \
          .help("Specify the compiler path.") .metaVar("OOC") .defaultValue("ooc") // TODO: CROSS PLATFORM ALARM
    
    parser addOption(backend) .addOption(repo) .addOption(package) .addOption(ooc)

    parser
}

main: func (args: ArrayList<String>) {
    parser := setupParser()

    if(args size() == 1) {
        parser displayHelp()
    } else {
        parser parse(args)
        
        if(parser values get("backend", String) isEmpty()) {
            parser error("You have to specify a backend.")
        }

        hasRepo := !parser values get("repo", String) isEmpty()
        hasPackage := !parser values get("package", String) isEmpty()

        /* check if there was a repo OR a package specified. */
        if(!((hasRepo && !hasPackage) || (hasPackage && !hasRepo))) {
            parser error("You have to specify either a repo or a package.")
        }
        
        repo := Repository new(File new(parser values get("repo", String)))
        repo getAllModules()
        match parser values get("backend", String) {
            case "sphinx" => {
                backend := SphinxRSTBackend new(repo)
                backend run()
                "Done." println()
            }
            case => {
                parser error("Available backends: sphinx")
            }
        }
    }
}
