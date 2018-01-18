# undiagjr

## Undocumented Diagnostics for the PCjr

![Screenshot of undiagjr.exe](https://lh3.googleusercontent.com/b6ReGx5kZIGEbKX_2FfMNFXiKowuK4mwa9ELjtXDiBAoah6YTZJz8pauX5BsTeXAnpmEvUFCcivjoCTCR-hpesvN4D-D1PBnmaIBtqQ-Cmhwhy2PfCc3YqfeS38soCNwX9UX-fArZk8)

![Press 7 to activate the test joystick with keyboard](https://lh3.googleusercontent.com/dOKcwze7HxfMKARkjBwKgqStodJdhGDlx3BVy7hCvFcdp3vp-0t1sDiV_jhi1-b0_DOx6S_kQ-Gu5P-Enkhko9ZbI2jQpw42RM3kL4_6v-yG_ZhQez2ocPKg8hmRt6WxE5wxzmunMbQ)


The IBM PCjr has some undocumented diagnostics modes:

*   Connect two joysticks
*   Press `Ctrl` + `Alt` + `Insert` keys to enter into diagnostics mode
*   Immediately after that, do:
    *   Press: Joy 1 button B, and Joy 2 buttons A & B for Manufacturing burn-in mode: enters diag loop mode without the diag screen
    *   Press: Joy 1 button A, and Joy 2 buttons A & B for Manufacturing system test mode: enters boot loop. Keeps booting
    *   Press: Joy 1 buttons A & B, and Joy 2 button B for Service loop-post mode: displays all diagnostics options, even if the hardware is not present
    *   Press: Joy 1 buttons A & B, and Joy 2 button A for Service system-test mode
    *   Press: Joy 1 buttons A & B, and joy 2 buttons A & B: enters boot loop with sound test

There is also some unused "joystick test" that cannot be triggered with jumping directly into it.

So, if you want to:

*   trigger the differerent System and Manufacturing test modes but you don't have two joysticks.
*   or you want to trigger the "secret joystick test" (press `7` to trigger it)

Say no more. Here is the tool for you.

* binary: [undiagjr.exe](https://github.com/ricardoquesada/pc-8088-misc/raw/master/undiagjr/undiagjr.exe)

_Disclaimer_: This is Work in progress. Not all tests are working ATM.


## Undocumented Diagnostics source code:

* [https://github.com/ricardoquesada/bios-8088/tree/master/ibm_pcjr][1]

Search for `int_80_diag_init`. That's the bootstrap for the diagnotics code.


## Vulnerability related to this tool

*   [IBM PCjr zero-day vulnerability][2]


[1]: https://github.com/ricardoquesada/bios-8088/tree/master/ibm_pcjr
[2]: https://retro.moe/2018/01/15/ibm-pcjr-zero-day-data-destroy-vulnerability/
