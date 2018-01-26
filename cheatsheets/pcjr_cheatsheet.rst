IBM PCjr cheatsheet
===================

.. contents:: Contents
   :depth: 1

PIC 8259
--------

Only one (master) PIC `8259`_ in the PCjr. There is no slave PIC.

* 0x20: Command and Status Register
* 0x21: Interrupt Mask Register and Data Register

Init Commands
~~~~~~~~~~~~~

+-------+---------------------------------------+
| 0x20  | Initialization Command Word 1 (ICW1)  |
+=======+=======================================+
|bit 0  | ``0``: ICW4 needed                    |
|       | ``1``: not needed                     |
+-------+---------------------------------------+
|bit 1  | ``0``: Cascade mode                   |
|       | ``1``: Single (should be 1 in PCjr)   |
+-------+---------------------------------------+
|bit 2  | Ignored in x86. Should be ``0``       |
+-------+---------------------------------------+
|bit 3  | ``0``: Edge triggered mode            |
|       | ``1``: Level triggered mode           |
+-------+---------------------------------------+
|bit 4  | ``1``: must be 1 to initialize PIC    |
+-------+---------------------------------------+
|bit 5-7| Not used. Should be ``0`` in x86      |
+-------+---------------------------------------+

+-------+---------------------------------------+
| 0x21  | Initialization Command Word 2 (ICW2)  |
+=======+=======================================+
|bit 0-2| Not used in x86                       |
+-------+---------------------------------------+
|bit 3-7| Specifies the x86 interrupt vector    |
|       | address times 8                       |
+-------+---------------------------------------+

+-------+---------------------------------------+
| 0x21  | Initialization Command Word 4 (ICW4)  |
+=======+=======================================+
|bit 0  | Set to 1 in x86                       |
+-------+---------------------------------------+
|bit 1  |0: manual EOI                          |
|       |1: controller perform automatic EOI    |
+-------+---------------------------------------+
|bit 2  | if bit 3 == 1:                        |
|       | 0: buffer slave                       |
|       | 1: buffer master                      |
+-------+---------------------------------------+
|bit 3  | 0: Non-buffer mode                    |
|       | 1: Buffer mode                        |
+-------+---------------------------------------+
|bit 4  | Special Fully Nested Mode. Not used   |
+-------+---------------------------------------+
|bit 5-7| Not used. Should be 0                 |
+-------+---------------------------------------+

Operation Commands
~~~~~~~~~~~~~~~~~~

+-------+---------------------------------------+
| 0x20  | Operation Command Word 2 (OCW2)       |
+=======+=======================================+
|bit 0-2| Interrupt level upon which controller |
|       | must react.                           |
+-------+---------------------------------------+
|bit 3-4| Reserved, must be ``0``               |
+-------+---------------------------------------+
|bit 5  | End Of Interrupt (EOI) request        |
+-------+---------------------------------------+
|bit 6  | Selection                             |
+-------+---------------------------------------+
|bit 7  | Rotation option                       |
+-------+---------------------------------------+

+-------+-------------------------------------------+
| 0x21  | Interrupt Mask Register (IMR)             |
+=======+===========================================+
|bit 0-7| IRQ0 - IRQ7. ``1``: Interrupt masked,     |
|       | ``0``: unmasked                           |
+-------+-------------------------------------------+

Example:
~~~~~~~~

.. code:: asm

    ; This is how the PCjr initializes the PIC
    mov     al,0b0001_0011          ;ICW1
    out     0x20,al
    mov     al,0b0000_1000          ;ICW2. IVT starts at 8 (1*8)
    out     0x21,al
    mov     al,0b0000_1001          ;ICW4
    out     0x21,al

    ; Enable vertical retrace interrupt
    mov     al,0b1101_1111          ;Vertical retrace interrupt unmasked
    out     0x21,al

    ; After receiving a hardware interrupt send the EOI command
    mov     al,0x20
    out     0x20,al


Timer 8253-5 (PIT)
------------------

+-------+--------------------------------------+
| 0x40  | Timer 0                              |
+=======+======================================+
|bit 0-7| Data port (read/write)               |
+-------+--------------------------------------+

+-------+--------------------------------------+
| 0x41  | Timer 1                              |
+=======+======================================+
|bit 0-7| Data port (read/write)               |
+-------+--------------------------------------+

+-------+--------------------------------------+
| 0x42  | Timer 2                              |
+=======+======================================+
|bit 0-7| Data port (read/write)               |
+-------+--------------------------------------+

+-------+-------------------------------------------------+
| 0x43  | Mode/Command register                           |
+=======+=================================================+
|bit 0  | ``0``: 16-bit binary, ``1``: BCD                |
+-------+-------------------------------------------------+
|bit 1-3| * ``0,0,0``: Mode 0: Interrupt on terminal count|
|       | * ``0,0,1``: Mode 1: hw retriggerable one-shot  |
|       | * ``0,1,0``: Mode 2: rate generator             |
|       | * ``0,1,1``: Mode 3: square wave generator      |
|       | * ``1,0,0``: Mode 4: software triggered strobe  |
|       | * ``1,0,1``: Mode 5: hardware triggered strobe  |
+-------+-------------------------------------------------+
|bit 4-5| * ``0,0``: Latch                                |
|       | * ``0,1``: Lo byte only                         |
|       | * ``1,0``: Hi byte only                         |
|       | * ``1,1``: Lo byte / Hi byte                    |
+-------+-------------------------------------------------+
|bit 6-7| * ``0,0``: Timer 0                              |
|       | * ``0,1``: Timer 1                              |
|       | * ``1,0``: Timer 2                              |
+-------+-------------------------------------------------+

Example:
~~~~~~~~

.. code:: asm

    ; reads timer 1 value
    mov     al,0b0100_0000          ;timer 1, latch
    out     0x43,al                 ;send the command
    push    ax                      ;delay to make sure the command reached
    pop     ax
    in      al,0x41                 ;read lsb from timer 1
    mov     ah,al
    in      al,0x41                 ;read msb from timer 1
    xchg    al,ah                   ;ax has the timer 1 value


PPI 8255-5
----------

+---------+---------------------------------------------------------------+
| 0x60    | 8255-5 Port A: Output                                         |
+=========+===============================================================+
| bit 0-7 | Configured as output. Not used by hw. Used to store keystrokes|
+---------+---------------------------------------------------------------+

+---------+---------------------------------------------------------------+
| 0x61    | 8255-5 Port B: Output                                         |
+=========+===============================================================+
| bit 0   | ``1``: Timer 2 gate                                           |
+---------+---------------------------------------------------------------+
| bit 1   | ``1``: Speaker data                                           |
+---------+---------------------------------------------------------------+
| bit 2   | ``0``: Graphics mode. ``1``: Alphanumeric mode                |
+---------+---------------------------------------------------------------+
| bit 3   | ``1``: Cassette motor off                                     |
+---------+---------------------------------------------------------------+
| bit 4   | ``1``: Disable internal beeper and cassette motor relay       |
+---------+---------------------------------------------------------------+
| bit 5-6 |  * ``0``, ``0``: 8253-5 timer 2                               |
|         |  * ``0``, ``1``: Cassette audio input                         |
|         |  * ``1``, ``0``: I/O channel audio in                         |
|         |  * ``1``, ``1``: 76496                                        |
+---------+---------------------------------------------------------------+
| bit 7   | Not used                                                      |
+---------+---------------------------------------------------------------+

+---------+---------------------------------------------------------------+
| 0x62    | 8255-5 Port C: Input                                          |
+=========+===============================================================+
| bit 0   | ``1``: Keyboard latched                                       |
+---------+---------------------------------------------------------------+
| bit 1   | ``0``: Internal MODEM card installed                          |
+---------+---------------------------------------------------------------+
| bit 2   | ``0``: Diskette drive card installed                          |
+---------+---------------------------------------------------------------+
| bit 3   | ``0``: 64kb memory and display expansion installed            |
+---------+---------------------------------------------------------------+
| bit 4   | Cassette data in                                              |
+---------+---------------------------------------------------------------+
| bit 5   | Input wired to the timer 2 output                             |
+---------+---------------------------------------------------------------+
| bit 6   | ``1``: Keyboard data                                          |
+---------+---------------------------------------------------------------+
| bit 7   | ``0``: Keyboard cable is connected                            |
+---------+---------------------------------------------------------------+

+---------+---------------------------------------------------------------+
| 0x63    | 8255-5 Command Port: Output                                   |
+=========+===============================================================+
| bit 0   | ``1``: Input, ``0``: Output, for Port C lsb                   |
+---------+---------------------------------------------------------------+
| bit 1   | ``1``: Input, ``0``: Output, for Port B                       |
+---------+---------------------------------------------------------------+
| bit 2   | ``0``: Mode 0, ``1``: Mode 1 for Port B - Simple I/O          |
+---------+---------------------------------------------------------------+
| bit 3   | ``1``: Input, ``0``: Output, for Port C msb                   |
+---------+---------------------------------------------------------------+
| bit 4   | ``1``: Input, ``0``: Output, for Port A                       |
+---------+---------------------------------------------------------------+
| bit 5-6 | ``00``: Mode 1, ``01``: Mode 2, ``1x``: Mode 3 for Port A     |
+---------+---------------------------------------------------------------+
| bit 7   | ``1``: for I/O mode                                           |
+---------+---------------------------------------------------------------+

Example:
~~~~~~~~

.. code:: asm

    ; Init 8255
    mov     al,0b1000_1001              ;Port C msb/lsb: input. Port B: output, mode 0
                                        ; Port A: output, mode 1
    out     0x63,al

NMI mask reg
------------

A read to port ``0xa0`` will clear the keyboard NMI latch. This latch causes an
NMI on the first rising edge of the keyboard data if the enable NMI bit (port
``0xa0`` bit 7) is on. This latch can also be read on the 8255 PCO. The program
can determine if a keystroke occurred while the NMI was I disabled by reading
the status of this latch. This latch must be cleared before another NMI can be
received.

+---------+---------------------------------------------------------------+
| 0xa0    | NMI mask reg                                                  |
+=========+===============================================================+
| bit 0-3 | Not used                                                      |
+---------+---------------------------------------------------------------+
| bit 4   | Not implemented. But ``0`` "enables" HRQ, ``1`` "disables" it |
+---------+---------------------------------------------------------------+
| bit 5   | ``0`` selects 1.1925Mhz input for timer 1. ``1`` uses timer 0 |
|         | output as input form timer 1                                  |
+---------+---------------------------------------------------------------+
| bit 6   | ``1`` timer 2 output into an IR diode. For diagnostics only   |
+---------+---------------------------------------------------------------+
| bit 7   | ``1`` enables NMI. ``0`` disables it                          |
+---------+---------------------------------------------------------------+

Example:
~~~~~~~~

.. code:: asm

    ; Disables NMI
    sub     al,al
    out     0xa0,al


TODO
====

*  0xc0: SN76496N
*  0xf0-0xff: diskette
*  0x200: joystick
*  0x2f8-0x2ff: serial port
*  0x3d0-0x3df: video subsystem
*  0x3f8-0x3ff: modem

.. _8259: http://www.brokenthorn.com/Resources/OSDevPic.html
.. _8253: http://wiki.osdev.org/Programmable_Interval_Timer
