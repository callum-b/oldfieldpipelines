import re
import sys
import numpy as np

def collect_values_mmb(inpath):
    r = re.compile("start_*")
    toreturn = {}
    with open(inpath, 'r') as f:
        header = f.readline().strip().split("\t")
        ntracks = len(header) -3 - len(list(filter(r.match, header)))
        tracknames = header[3 : 4 + ntracks]
        # print(tracknames)
        batches={}
        rootnames=[]
        first_f = tracknames.pop(0).split("/")[-1]
        while tracknames: # this whole loop is just to get batches, which is a list of N values, where N is the number of batches of bws that were mapped, and each value of N is the number of bws in that batch
            n_in_batch = 1
            first_split = re.split(r'_\d+', first_f)
            rootnames.append(first_split[0])
            # print("First: " + first_split[0])
            next_f = tracknames.pop(0).split("/")[-1]
            next_split = re.split(r'_\d+', next_f)
            while first_split[0] == next_split[0]:
                # print("Next: " + next_split[0])
                n_in_batch+=1
                if tracknames:
                    next_f = tracknames.pop(0).split("/")[-1]
                    next_split = re.split(r'_\d+', next_f)
                else:
                    next_f = "time to exit!"
                    next_split = ["wheeeeeeee"]
            batches[first_split[0]] = n_in_batch
            toreturn[first_split[0]] = []
            first_f = next_f
        for myline in f.readlines():
            myline=myline.split("\t")[3 : 4 + ntracks]
            prev=0
            results = []
            for myname in rootnames:
                toreturn[myname].append(myline[prev:prev+batches[myname]])
                prev+=batches[myname]
    return toreturn

def corrcoeff_each(mydict):
    toreturn={}
    for myname in mydict.keys():
        x=np.array(mydict[myname], dtype='float')
        x=x[~np.isnan(x).any(axis=1)]
        y=np.corrcoef(x, rowvar=False)
        toreturn[myname] = np.average(y[np.triu_indices(y.shape[0],1)])
    return toreturn

def main() -> int:
    fname = sys.argv[1]
    outname = fname.split("/")[-1]
    for key,val in corrcoeff_each(collect_values_mmb(fname)).items():
        print(outname + "\t" + str(key) + "\t" + str(val))
    return 0

if __name__ == '__main__':
    sys.exit(main())