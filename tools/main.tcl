proc parse-sam-file {source} {
    return [exec -ignorestderr python3 tools/sam/samparser.py $source]
}

clips load tools/generate.clp

clips reset

clips run -1
