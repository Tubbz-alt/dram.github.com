proc parse-sam-file {source} {
    return [exec -ignorestderr python3 tools/sam/samparser.py $source]
}

proc parse-sam-file-ng {source} {
    set contents {}

    set channel [open $source]
    while {gets $channel line} {
	puts stderr $line
    }
    close $channel
}

clips load tools/generate.clp

clips reset

clips run -1
