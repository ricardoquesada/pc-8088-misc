#!/usr/bin/env python3
# -----------------------------------------------------------------------------
# converts VGM files to a more compact file format (optimized format for Tandy)
# -----------------------------------------------------------------------------
"""
Tool to convert VGM (Video Game Music) to PVM (Player VGM Music)
It is the same, but smaller, around 30% smaller.

For the moment, the only supported chip is SN76489 (Sega Master System in
Deflemask).
"""
import argparse
import os
import struct
import sys


__docformat__ = 'restructuredtext'


class ToPVM:
    """The class that does all the conversions"""

    # 3 MSB bits are designed for commands
    # 5 LSB bits are for data for the command
    DATA = 0b00000000               # 000xxxxx (xxxxxx = len of data)
    DATA_EXTRA = 0b00100000         # 001----- next byte will have the data len
    DELAY = 0b01000000              # 010xxxxx (xxxxxx = cycles to delay)
    DELAY_EXTRA = 0b01100000        # 011----- next byte will have the delay
    END = 0b10000000                # 100-----

    def __init__(self, vgm_fd):
        self._vgm_fd = vgm_fd
        path = os.path.dirname(vgm_fd.name)
        basename = os.path.basename(vgm_fd.name)
        name = '%s.%s' % (os.path.splitext(basename)[0], 'pvm')
        self._out_filename = os.path.join(path, name)

        self._output_data = bytearray()
        self._current_port_data = bytearray()

        self._should_loop = False
        self._pvm_loop_offset = 0

    def run(self):
        """Execute the conversor."""
        with open(self._out_filename, 'w+') as fd_out:
            # FIXME: Assuming VGM version is 1.50 (64 bytes of header)
            header = bytearray(self._vgm_fd.read(0x40))

            print('Converting: %s -> %s...' %
                    (self._vgm_fd.name, self._out_filename), end='')

            # 0x00: "Vgm " (0x56 0x67 0x6d 0x20) file identification (32 bits)
            if header[:4].decode('utf-8') != 'Vgm ':
                print(' failed. Not a valid VGM file')
                return

            # 0x08: Version number (32 bits)
            #  Version 1.50 is stored as 0x00000150, stored as 0x50 0x01 0x00 0x00.
            #  This is used for backwards compatibility in players, and defines which
            #  header values are valid.
            vgm_version = struct.unpack_from("<I", header, 8)[0]
            if vgm_version != 0x150:
                print(' failed. Invalid VGM version: %x (not 0x150)' %
                        vgm_version)
                return

            # 0x0c: SN76489 clock (32 bits)
            #  Input clock rate in Hz for the SN76489 PSG chip. A typical value is
            #  3579545. It should be 0 if there is no PSG chip used.
            sn76489_clock = struct.unpack_from("<I", header, 12)[0]
            if sn76489_clock != 3579545:
                print(' failed. Not a VGM SN76489 song')
                return

            # 0x04: Eof offset (32 bits)
            #  Relative offset to end of file (i.e. file length - 4).
            #  This is mainly used to find the next track when concatanating
            #  player stubs and multiple files.
            file_len = struct.unpack_from("<I", header, 4)[0]
            data = bytearray(self._vgm_fd.read(file_len + 4 - 0x40))

            # 0x1c: Loop offset (32 bits)
            #  Relative offset to loop point, or 0 if no loop.
            #  For example, if the data for the one-off intro to a song was in bytes
            #  0x0040-0x3fff of the file, but the main looping section started at
            #  0x4000, this would contain the value 0x4000-0x1c = 0x00003fe4.
            loop = struct.unpack_from("<I", header, 0x1c)[0]
            self._should_loop = True if loop != 0 else False
            vgm_loop_offset = loop + 0x1c - 0x40

            i = 0
            while i < len(data):
                # when looping, flush RLE since loop should jump to start
                # of valid code
                if self._should_loop and i == vgm_loop_offset:
                    self.flush_current_port_data()
                    self._pvm_loop_offset = len(self._output_data)

                if data[i] == 0x50:
                    self.add_port_data(data[i+1])
                    i = i+2
                elif data[i] == 0x61:
                    # unpack little endian unsigned short
                    delay = struct.unpack_from("<H", data, i+1)[0]
                    self.add_n_delay(delay)
                    i = i+3
                elif data[i] == 0x62:
                    self.add_single_delay()
                    i = i+1
                elif data[i] == 0x66:
                    self.add_end()
                    break
                else:
                    raise Exception('Unknown value: data[0x%x] = 0x%x' %
                            (i, data[i]))

            self.prepend_header()

            old_len = file_len + 4
            new_len = len(self._output_data)
            if new_len < 65536:
                fd_out.buffer.write(self._output_data)
                print(' done (%d%% smaller)' % (100-(100*new_len/old_len)))
            else:
                print(' failed. converted size %d > 65535' % new_len)

    def prepend_header(self):
        HEADER_LEN = 16
        VERSION_LO = 0
        VERSION_HI = 1
        header = bytearray()

        # signature: 4 bytes
        header += 'PVM '.encode('utf-8')

        # total len: 4 bytes
        l = len(self._output_data) + HEADER_LEN
        total_len = struct.pack("<I", l)
        header += total_len

        # version: 2 bytes. minor, major
        header.append(VERSION_LO)
        header.append(VERSION_HI)

        # flags: 2 bytes
        # which procesor is supported
        #  either PAL/NTSC
        #  clock
        #  should loop
        flags = 0x0
        if self._should_loop:
            flags |= 0x1

        header.append(0)
        header.append(flags)

        # loop offset: 4 bytes
        loop_offset = struct.pack("<I", self._pvm_loop_offset)
        header += loop_offset

        self._output_data = header + self._output_data

    def add_port_data(self, byte_data):
        self._current_port_data.append(byte_data)

    def add_single_delay(self):
        self.flush_current_port_data()
        self._output_data.append(self.DELAY | 1)

    def add_n_delay(self, delay):
        delay_val = delay // 0x02df
        if delay_val == 0:
            return

        self.flush_current_port_data()

        if delay_val > 31:
            self._output_data.append(self.DELAY_EXTRA)
            self._output_data.append(delay_val)
        else:
            self._output_data.append(self.DELAY | delay_val)

    def add_end(self):
        self._output_data.append(self.END)

    def flush_current_port_data(self):
        l = len(self._current_port_data)
        if l == 0:
            return

        if l > 31:
            self._output_data.append(self.DATA_EXTRA)
            self._output_data.append(l)
        else:
            self._output_data.append(self.DATA | l)
        self._output_data = self._output_data + self._current_port_data
        self._current_port_data = bytearray()


def parse_args():
    """Parse the arguments."""
    parser = argparse.ArgumentParser(
        description='Converts VGM to PVM',
        epilog="""Example:

$ %(prog)s my_music.vgm
""")
    parser.add_argument('filenames',
            metavar='<filename>',
            nargs='+',
            type=argparse.FileType('rb'),
            help='files to convert to pvm format')

    args = parser.parse_args()
    return args


def main():
    """Main function."""
    args = parse_args()

    print('VGM to PVM v0.2 - riq/pvm - http://pungas.space\n')
    for fd in args.filenames:
        ToPVM(fd).run()

if __name__ == "__main__":
    main()
