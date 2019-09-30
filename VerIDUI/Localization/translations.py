from os import walk
import re

def unique(list):
    ulist = []
    for val in list:
        if val not in ulist:
            ulist.append(val)
    return ulist

def getSwiftFiles(dir, swiftFiles):
    for (dirpath, dirnames, filenames) in walk(dir):
        for name in filenames:
            if name.endswith(".swift"):
                swiftFiles.append(dirpath+"/"+name)
        for dirname in dirnames:
            if dirname != "build":
                getSwiftFiles(dirpath+dirname, swiftFiles)
swiftFiles = []
getSwiftFiles("../", swiftFiles)

swiftFiles = unique(swiftFiles)

def strings():
    words = []
    for file in swiftFiles:
        f = open(file, "r")
        src = f.read()
        matchlist = re.findall(r"translatedStrings\?*\[\"(.+?)\"", src)
        for word in matchlist:
            if word not in words:
                words.append(word)
    words.sort()
    return words
