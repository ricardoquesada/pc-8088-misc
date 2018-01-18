# undiagjr

## Undocumented Diagnostics for the PCjr

![Screenshot of undiagjr.exe](https://lh3.googleusercontent.com/enB6lMrmQLSn0-zB5awuw4GOxXLN-1b6gjcJm-L03aq_rGPUjN1t3n_PcBXdEAwuCQpNDFXNI3d-abgt-dqb0Jp0j9tMRwLBPrJnU3hmeBGusLw7Xc617pxt1-iL-ErlfTJWrAgzI6s1cPQeuALEx4_o5JbqzBPtH_bOYAlbiOnejQgXC3IRheyLclT3retBaXIKgXtN2tCh4cSJuCPgtmo7vqtWeXllkoYfLBMOSohvdC8r0muUiFCNQ0dQAMwvVFuXwZ7JQTeKFKDL59zks8mfwJ5pCfD4t1i59LEfxznWAb_iQxixWu8-K5YvnKpyuGBkuoSCYU1g0yYcpG-dQRuvVWMRhTfQz8iWdXAvd1Cy94GHaOtkFvcAfX5JqozdfuO3wdPDa8dI_gr96TJXULUjJv4pw7zhQ5oeMsm3RpgRaZWgDtqTjz8YGaJwdPXFwXKtUWWS4QrbB_rVt1L6MURkuGpI14NuR9l_M7aOH0a9QDLXv9xRlA8B2mKNjqQ93XZRUVG8-it7KpkkUR34i_y8J0t3nwqH6sPCRrTrI1klzYtZzriFZq3rSKm_hGOuJCuYkvYl6XglP5RMajQOXkbhkbm39qZPxQhVH3b9cZh6gGNI-1BaEueC8kfMdk7HzcwRCXUQhU7qrm68qioLBWvL0B70YvLbTw)

![Press 7 to activate the test joystick with keyboard](https://lh3.googleusercontent.com/wlwNSQxCWugfNr86RyF8Pc9nHoXGFkZyL9KAjje-R5UqjLvCdQsKazsuzdzsdJKBcrVJe49uKEnt5y2jWf9l-7ijrI016Htsv10ENZzqGQ4Fvyij1kO6iEK4-wpPfgP9y7CCOgcHhQ_qIYrS-cz-tD7e7t5ffnIYbnNuZVwHKUq1bBSa2s9nwM9BaP6PQ4rKqHDi0vmynQzp25M58PqqrsmI2ohKsOK7llaMyP3yNWR7pQI3ehhugkCRtuRN2OlsVa_5H8j8hpw7NDvL0KwpvDkdCdP-zm3pK3OgcWOmLRqwKwAPsVQoru53Tzec-hU_bkjbahz4qKb0SGK26QLoVRvJNozXQJC2AjsXMeBxtVM_CkeCMxsMm4XJvXdvr7K6joEioKG7hARTrS-5_OT89IZCZ3r7nu-HQTu8HgcGzkuc0SSOGi2Gf94-5IHN-okqjeA2GEHkpMfPROkQYD0jHHzMrstDgeuScl7rvST_TgCrXvNwBHnVBZCXP2eZ3pagD91Ti6l_lRK0YB8CiC8E6qoQNr4TKnR2xIY0UM0oeza9pgGHR51WNpKd0PBxq-S4PW04lTLiPiMnn6jDJ8AbMToF857TMG6LK5WttYwo)


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

* binary: [undiagjr.exe](https://github.com/ricardoquesada/ibm_pcjr-misc/raw/master/undiagjr/undiagjr.exe)

_Disclaimer_: This is Work in progress. Not all tests are working ATM.


## Undocumented Diagnostics source code:

* [https://github.com/ricardoquesada/bios-8088/tree/master/ibm_pcjr][1]

Search for `int_80_diag_init`. That's the bootstrap for the diagnotics code.


## Vulnerability related to this tool

*   [IBM PCjr zero-day vulnerability][2]


[1]: https://github.com/ricardoquesada/bios-8088/tree/master/ibm_pcjr
[2]: https://retro.moe/2018/01/15/ibm-pcjr-zero-day-data-destroy-vulnerability/
