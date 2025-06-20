import sys

toprint = {}

with open(sys.argv[1], "r") as f:
    for myline in f.readlines():
        if myline[0] != "#":
            tempdict = {}
            info = myline.split("\t")[-1].split("; ")
            for elem in info:
                if len(elem) > 2:
                    datum = elem.split(" ")
                    tempdict[datum[0]] = datum[1].strip('\"')
            if tempdict["gene_id"] not in toprint:
                toprint[tempdict["gene_id"]] = tempdict["gene_name"] + "\t" + tempdict["gene_type"]

with open(sys.argv[2], "w") as out:
    for key, value in toprint.items():
        out.write(key + "\t" + value + "\n")

