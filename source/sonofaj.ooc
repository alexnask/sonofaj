import io/[File, FileReader]
import sonofaj/[Nodes, Repository]
import sonofaj/backends/SphinxRST

main: func {
    repo := Repository new(File new("repo"))
    repo getModule("test") .getModule("structs/ArrayList")
    backend := SphinxRSTBackend new(repo)
    backend run()
}
