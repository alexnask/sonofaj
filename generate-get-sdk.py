#!/usr/bin/env python
from __future__ import with_statement
import os

IGNORE = [
    'ooc-yajl/test',
    'ooc-yajl/simple-test',
    'ooc-yajl/very-simple-test',
    'ooc-yajl/yajl/Yajl',
    'optparse/test',
    'optparse/optparse/Parser',
    'optparse/optparse/Option'
]

if not 'ROCK_SDK' in os.environ:
    raise Exception('You have to set $ROCK_SDK')

sdk = os.environ['ROCK_SDK']

def visit(root):
    root_len = len(root)
    for dirname, dirnames, fnames in os.walk(root):
        if dirname.startswith('.'):
            continue
        # all dirs are actually subdirs of `root`
        package_path = dirname[root_len:].replace(os.pathsep, '/').strip('/')
        for fname in fnames:
            if fname.endswith('.ooc'):
                if len(package_path) == 0:
                    modulename = fname[:-4]
                else:
                    modulename = package_path + '/' + fname[:-4]
                if modulename not in IGNORE:
                    yield modulename

with open('get-sdk.ooc', 'w') as f:
    for module in visit(sdk):
        f.write('import %s\n' % module)
