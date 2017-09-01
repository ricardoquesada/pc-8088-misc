#!/usr/bin/env python3
# ----------------------------------------------------------------------------
# converts raw 160x100x16 to packed 160x100 - riq
# ----------------------------------------------------------------------------
"""
Tool to convert raw to 160x100x16 for Tandy 1000
"""
import argparse
import sys


__docformat__ = 'restructuredtext'


def pairwise(iterable):
    """s -> (s0, s1), (s2, s3), (s4, s5), ..."""
    a = iter(iterable)
    return zip(a, a)


def run(image_file, output_fd):
    """Execute the conversor."""
    output = bytearray()
    with open(image_file, 'rb') as f:
        bytes = bytearray(f.read(160*100))
        for a, b in pairwise(bytes):
            output.append(a << 4 | b)
    output_fd.buffer.write(output)


def parse_args():
    """Parse the arguments."""
    parser = argparse.ArgumentParser(
        description='Converts a 160x100 16 .raw images to packed 160x100',
        epilog="""Example:

$ %(prog)s -o image.tandy image.raw
""")
    parser.add_argument('filename', metavar='<filename>',
                        help='file to convert')
    parser.add_argument('-o', '--output-file', metavar='<filename>',
                        help='output file. Default: stdout')

    args = parser.parse_args()
    return args


def main():
    """Main function."""
    args = parse_args()
    if args.output_file is not None:
        with open(args.output_file, 'w+') as fd:
            run(args.filename, fd)
    else:
        run(args.filename, sys.stdout)

if __name__ == "__main__":
    main()
