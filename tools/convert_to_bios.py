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
import math
from collections import namedtuple


__docformat__ = 'restructuredtext'

BIOSFormat = namedtuple('BIOSFormat', 'width, height, colors')
formats = {}
formats[4] = BIOSFormat(320, 200, 4)        # 320 x 200 4 colors
formats[6] = BIOSFormat(640, 200, 2)        # 640 x 200 2 colors
formats[8] = BIOSFormat(160, 200, 16)       # 160 x 200 16 colors
formats[9] = BIOSFormat(320, 200, 16)       # 320 x 200 16 colors
formats[10] = BIOSFormat(640, 200, 4)       # 640 x 200 4 colors


def parse_line_2(array):
    """converts 2 bytes into 1 byte"""
    bitmap = bytearray(array)
    ba = bytearray()
    for i in range(len(bitmap) // 2):
        hi = bitmap[i * 2 + 0] & 0xf
        lo = bitmap[i * 2 + 1] & 0xf
        byte = hi << 4 | lo
        ba.append(byte)
    return ba


def parse_line_4(array):
    """converts 4 bytes into 1 byte"""
    bitmap = bytearray(array)
    ba = bytearray()
    for i in range(len(bitmap) // 4):
        b1 = bitmap[i * 4 + 0] & 0x3
        b2 = bitmap[i * 4 + 1] & 0x3
        b3 = bitmap[i * 4 + 2] & 0x3
        b4 = bitmap[i * 4 + 3] & 0x3
        byte = (b1 << 6) | (b2 <<4) | (b3 << 2) | b4
        ba.append(byte)
    return ba


def parse_line_8(array):
    """converts 8 bytes into 1 byte"""
    bitmap = bytearray(array)
    ba = bytearray()
    for i in range(len(bitmap) // 8):
        b1 = bitmap[i * 8 + 0] & 0x1
        b2 = bitmap[i * 8 + 1] & 0x1
        b3 = bitmap[i * 8 + 2] & 0x1
        b4 = bitmap[i * 8 + 3] & 0x1
        b5 = bitmap[i * 8 + 4] & 0x1
        b6 = bitmap[i * 8 + 5] & 0x1
        b7 = bitmap[i * 8 + 6] & 0x1
        b8 = bitmap[i * 8 + 7] & 0x1
        byte = (b1 << 7) | (b2 << 6) | (b3 << 5) | (b4 << 4) | (b5 << 3) | (b6 << 2) | (b7 << 1) | b8
        ba.append(byte)
    return ba

def parse_line(array, colors):
    if colors == 16:
        return parse_line_2(array)
    if colors == 4:
        return parse_line_4(array)
    if colors == 2:
        return parse_line_8(array)
    return None


def write_to_file(lines, out_fd, gfx_format):
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

    bits_per_color = math.log2(gfx_format.colors)
    size = gfx_format.height * gfx_format.width * (bits_per_color / 8)
    lines_per_block = gfx_format.height // 4
    ordered = []
    for i in range(4):
        for j in range(lines_per_block):
            ordered.append(lines[j * 4 + i])
        ordered.append(bytearray(192))

    for l in ordered:
        out_fd.buffer.write(l)


def run(image_file, gfx_format, output_fd):
    """execute the conversor"""
    lines = []
    width = gfx_format.width
    with open(image_file, 'rb') as f:
        for chunk in iter(lambda: f.read(width), b''):
            lines.append(parse_line(chunk, gfx_format.colors))

    write_to_file(lines, output_fd, gfx_format)


def parse_args():
    """parse the arguments"""
    parser = argparse.ArgumentParser(
        description='Converts .raw images to different formats supported by '
        'BIOS' , epilog="""Example:

$ %(prog)s -f 9 -o image.tandy image.raw
""")
    parser.add_argument('filename', metavar='<filename>',
                        help='file to convert')
    parser.add_argument('-g', '--bios_gfx_mode', type=int, metavar='BIOS_graphics_mode',
                        dest='format', help='output file. Default: stdout', default=4)
    parser.add_argument('-o', '--output-file', metavar='<filename>',
                        help='output file. Default: stdout')

    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    if args.output_file is not None:
        with open(args.output_file, 'w+') as fd:
            run(args.filename, formats[args.format], fd)
    else:
        run(args.filename, formats[args.format], sys.stdout)

if __name__ == "__main__":
    main()
