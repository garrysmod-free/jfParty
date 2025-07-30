jrParty = jrParty or {}


/* What do after disconnect Leader Patty
    0 - Disband Party
    1(default) - Promote Random Player if players has, or disband
*/
jrParty.D_WhatDoAfterLeave = 1

jrParty.ESPEnabled = true -- Party ESP Enable/Disable

jrParty.MarkEnabled = true
jrParty.MarkTime = 15 -- seconds

jrParty.Limites = { -- Player Members Count Limit
    default = 5,
    user = 5,
    superadmin = 100
}