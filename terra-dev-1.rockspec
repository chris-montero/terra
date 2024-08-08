package = "terra"
version = "dev-1"
source = {
    url = "git://github.com/chris-montero/terra.git"
}
description = {
    homepage = "http://github.com/chris-montero/terra",
    summary = "What if you didn't have to write Electron apps anymore?",
    detailed = "A sane, desktop-native, application development framework.",
    license = "GNU GPL v2",
}
dependencies = {
    "lua ~> 5.1",
    "lgi ~> 0.9.2-1",
    "tstation ~> dev-1",
    "stdcolor ~> dev-1",
}
build = {
    type = "builtin",
    modules = {
        ["terra.orchard"] = "l/orchard.lua",

        -- terra window tools
        ["terra.window.xcb"] = "l/window/xcb.lua",
        ["terra.window.internal"] = "l/window/internal.lua",

        -- TODO: can I get rid of these events files?
        ["terra.events.xcb"] = "l/events/xcb.lua",
        ["terra.events.common"] = "l/events/common.lua",

        ["terra.app"] = "l/app.lua",

        ["terra.sigtools"] = "l/sigtools.lua",
        ["terra.time"] = "l/time.lua",
        ["terra.object"] = "l/object.lua",
        ["terra.element"] = "l/element.lua",

        -- terra input
        ["terra.input.click"] = "l/input/click.lua",
        ["terra.input.clickmap"] = "l/input/clickmap.lua",
        ["terra.input.clickbind"] = "l/input/clickbind.lua",
        ["terra.input.key"] = "l/input/key.lua",
        ["terra.input.keymap"] = "l/input/keymap.lua",
        ["terra.input.keybind"] = "l/input/keybind.lua",

        -- oak tools
        ["terra.oak.shape"] = "l/oak/shape.lua",
        ["terra.oak.source"] = "l/oak/source.lua",
        ["terra.oak.size"] = "l/oak/size.lua",
        ["terra.oak.align"] = "l/oak/align.lua",
        ["terra.oak.padding"] = "l/oak/padding.lua",
        ["terra.oak.border"] = "l/oak/border.lua",
        ["terra.oak.internal"] = "l/oak/internal.lua",

        -- oak element internals
        ["terra.oak.elements.internal"] = "l/oak/elements/internal.lua",
        ["terra.oak.elements.element"] = "l/oak/elements/element.lua",

        -- oak branches
        ["terra.oak.elements.branches.internal"] = "l/oak/elements/branches/internal.lua",
        ["terra.oak.elements.branches.branch"] = "l/oak/elements/branches/branch.lua",
        ["terra.oak.elements.branches.el"] = "l/oak/elements/branches/el.lua",
        ["terra.oak.elements.branches.horizontal"] = "l/oak/elements/branches/horizontal.lua",
        ["terra.oak.elements.branches.vertical"] = "l/oak/elements/branches/vertical.lua",
        -- ["terra.oak.elements.branches.horizontal"] = "l/oak/elements/branches/horizontal.lua",
        -- ["terra.oak.elements.branches.vertical"] = "l/oak/elements/branches/vertical.lua",
        ["terra.oak.elements.branches.root"] = "l/oak/elements/branches/root.lua",

        -- oak leaves
        ["terra.oak.elements.leaves.leaf"] = "l/oak/elements/leaves/leaf.lua",
        ["terra.oak.elements.leaves.bg"] = "l/oak/elements/leaves/bg.lua",
        ["terra.oak.elements.leaves.text"] = "l/oak/elements/leaves/text.lua",
        ["terra.oak.elements.leaves.svg"] = "l/oak/elements/leaves/svg.lua",

        -- terra tools
        ["terra.tools.table"] = "l/tools/table.lua",
        ["terra.tools.tracker"] = "l/tools/tracker.lua",
        ["terra.tools.shapers"] = "l/tools/shapers.lua",

        -- terra internals
        -- TODO: remove this from the release build
        ["terra.internal.unveil"] = "l/internal/unveil.lua",

        -- C side terra internals
        ["terra.internal.scairo"] = {
            sources = { 
                "c/src/scairo.c",
                "c/src/lhelp.c",
                "c/src/app.c",
                "c/src/util.c",
            },
            libraries = {
                "xcb",
                "xcb-keysyms",
                "cairo",
            },
        },
        ["terra.internal.spixmap"] = {
            sources = { 
                "c/src/spixmap.c",
                "c/src/lhelp.c",
                "c/src/app.c",
                "c/src/util.c",
            },
            libraries = {
                "xcb",
                "xcb-keysyms",
                "X11",
            },
        },
        ["terra.internal.swin"] = {
            sources = { 
                "c/src/util.c",
                "c/src/app.c",
                "c/src/swin.c",
                "c/src/lhelp.c",
                "c/src/windows/xcb.c"
            },
            libraries = {
                "xcb",
                "xcb-keysyms",
                "xcb-cursor",
                "X11",
            },
            incdirs = {
                "c/src",
            },
        },
        ["terra.internal.application"] = {
            -- defines = {
            --     "DEBUG=1",
            -- },
            sources = { 
                "c/src/application.c",
                "c/src/app.c",
                "c/src/lhelp.c",
                "c/src/terra_xkb.c",
                "c/src/event.c",
                "c/src/util.c",
                "c/src/xdraw.c",
            },
            libraries = {
                "luajit-5.1",
                "xcb",
                "xcb-keysyms",
                "xcb-cursor",
                "xcb-errors",
                "cairo",
                "ev",
                "xkbcommon",
                "xkbcommon-x11",
            },
            incdirs = {
                "c/src",
            },
        },
    }
}
