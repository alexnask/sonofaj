import io/[File, FileReader]
import sonofaj/[Nodes, Repository]
import sonofaj/backends/SphinxRST

main: func {
    repo := Repository new(File new("repo"))
    repo getModule("test") .getModule("structs/ArrayList") .getModule("structs/List")
    backend := SphinxRSTBackend new(repo)
    backend run()
}
