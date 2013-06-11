#!/usr/bin/env python
import json
import sys

try:
    json.load(open(sys.argv[1],'r'))
except:

    sys.stdout.write("%s:1: Don't know where the error is, but there is one, PHP returned NULL\n" % sys.argv[1])
    sys.exit(1)
