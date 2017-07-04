#!/usr/bin/env python3
# ----------------------------------------------------------------------------
# converts raw 320x200x16 to Tandy 1000 320x200x16 mode - riq
# ----------------------------------------------------------------------------
"""
Tool to convert raw to 320x200x16 for Tandy 1000
"""
import argparse
import os
import sys


__docformat__ = 'restructuredtext'


def parse_line(array):
    """convert bytes to nibbles"""
    bitmap = bytearray(array)
    ba = bytearray()
    for i in range(len(bitmap) // 2):
        hi = bitmap[i * 2]
        lo = bitmap[i * 2 + 1]
        byte = hi << 4 | lo
        ba.append(byte)
    return ba


def write_to_file(lines, out_fd):
    """write files to output fd"""
    # reorder lines
    # raw format    ---> tandy 1000 format
    #   line 0            line 0
    #   line 1            line 4
    #   line 2            line 8
    #   line 3            line 12
    #   line 4            line 16
    #   line 5            line 20
    #   line 6            line 24
    #   line 7            line 28
    # ...
    ordered = []
    for i in range(4):
        for j in range(50):
            ordered.append(lines[j * 4 + i])
        ordered.append(bytearray(192))

    for l in ordered:
        out_fd.buffer.write(l)


def run(image_file, output_fd):
    """execute the conversor"""
    lines = []
    with open(image_file, 'rb') as f:
        for chunk in iter(lambda: f.read(320), b''):
            lines.append(parse_line(chunk))

    write_to_file(lines, output_fd)


def parse_args():
    """parse the arguments"""
    parser = argparse.ArgumentParser(
        description='Converts .raw 320x200x16 images into Tandy 1000'
        '320x200x16 images', epilog="""Example:

$ %(prog)s -o image.tandy image.raw
""")
    parser.add_argument('filename', metavar='<filename>',
                        help='file to convert')
    parser.add_argument('-o', '--output-file', metavar='<filename>',
                        help='output file. Default: stdout')

    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    if args.output_file is not None:
        with open(args.output_file, 'w+') as fd:
            run(args.filename, fd)
    else:
        run(args.filename, sys.stdout)

if __name__ == "__main__":
    main()
