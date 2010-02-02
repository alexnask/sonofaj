import io/[File, FileReader]
import sonofaj/Repository
import yajl/Yajl

main: func {
    repo := Repository new(File new("repo"))
    repo getModule("structs/ArrayList")
    repo getModule("lang/types")
}
