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
    "luv",
}
build = {
    type = "builtin",
    modules = {
        ["terra.orchard"] = "l/orchard.lua",
        ["terra.sigtools"] = "l/sigtools.lua",
        ["terra.object"] = "l/object.lua",
        ["terra.element"] = "l/element.lua",

        -- luv abstraction
        -- TODO: should I go this route?
        -- ["terra.suv.tcp"] = "l/suv/tcp.lua",
        -- ["terra.suv.internal.util"] = "l/suv/internal/util.lua",
        -- ["terra.suv.internal.stream"] = "l/suv/internal/stream.lua",
        -- ["terra.suv.internal.handle"] = "l/suv/internal/handle.lua",

        -- EXPERIMENTAL: try to use plenary's async abstraction
        -- ["terra.async.uv_async"] = "l/async/uv_async.lua",
        -- ["terra.async.async"] = "l/async/async.lua",
        -- ["terra.async.rotate"] = "l/async/rotate.lua",

        -- EXPERIMENTAL: an api that just does what people actually want 
        -- to do with tcp connections: listen for connections as a server, 
        -- or listen for data as a client.
        ["terra.abonaments.tcp.client"] = "l/abonaments/tcp/client.lua",

        ["terra.promise"] = "l/promise.lua",
        ["terra.puv"] = "l/puv.lua",

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
        -- TODO: move all l/oak/elements/element.lua to l/oak/elements/internal.lua
        -- TODO: same with branches and leaves
        ["terra.oak.elements.internal"] = "l/oak/elements/internal.lua",
        ["terra.oak.elements.element"] = "l/oak/elements/element.lua",

        -- oak branches
        ["terra.oak.elements.branches.internal"] = "l/oak/elements/branches/internal.lua",
        ["terra.oak.elements.branches.branch"] = "l/oak/elements/branches/branch.lua",
        ["terra.oak.elements.branches.el"] = "l/oak/elements/branches/el.lua",
        ["terra.oak.elements.branches.horizontal"] = "l/oak/elements/branches/horizontal.lua",
        ["terra.oak.elements.branches.vertical"] = "l/oak/elements/branches/vertical.lua",
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
        ["terra.tools.color"] = "l/tools/color.lua",
        ["terra.tools.enum"] = "l/tools/enum.lua",

        -- platform-independent common code
        ["terra.platforms.common.window"] = "l/platforms/common/window.lua",
        ["terra.platform"] = {
            sources = { 
                "c/src/platform.c",
            },
            libraries = {
            },
            incdirs = {
                "c/src",
            },
        },

        -- xcb platform code
        ["terra.platforms.xcb.app"] = "l/platforms/xcb/app.lua",
        ["terra.platforms.xcb.window"] = "l/platforms/xcb/window.lua",
        ["terra.platforms.xcb.scairo"] = {
            sources = {
                "c/src/lhelp.c",
                "c/src/util.c",

                "c/src/xcb/scairo.c",
                "c/src/xcb/xlhelp.c",
                "c/src/xcb/xcb_ctx.c",
                -- "c/src/util.c",
            },
            libraries = {
                "xcb",
                "xcb-keysyms",
                "cairo",
            },
            incdirs = {
                "c/src",
            },
        },
        ["terra.platforms.xcb.spixmap"] = {
            sources = {
                "c/src/lhelp.c",
                "c/src/util.c",

                "c/src/xcb/spixmap.c",
                "c/src/xcb/xlhelp.c",
                "c/src/xcb/xcb_ctx.c",
            },
            libraries = {
                "xcb",
                "xcb-keysyms",
                "X11",
            },
            incdirs = {
                "c/src",
            },
        },
        ["terra.platforms.xcb.swin"] = {
            sources = {
                "c/src/lhelp.c",
                "c/src/util.c",

                "c/src/xcb/swin.c",
                -- "c/src/xcb/util.c",
                "c/src/xcb/xcb_ctx.c",
                "c/src/xcb/xlhelp.c",
                "c/src/xcb/window.c"
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
        ["terra.platforms.xcb.ctx"] = {
            -- defines = {
            --     "DEBUG=1",
            -- },
            sources = {
                "c/src/lhelp.c",
                "c/src/util.c",

                "c/src/xcb/context.c",
                "c/src/xcb/xcb_ctx.c",
                "c/src/xcb/xlhelp.c",
                "c/src/xcb/terra_xkb.c",
                "c/src/xcb/event.c",
                "c/src/xcb/xutil.c",
                "c/src/xcb/vidata.c",
            },
            libraries = {
                "luajit-5.1",
                "xcb",
                "xcb-keysyms",
                "xcb-cursor",
                "xcb-errors",
                "cairo",
                "xkbcommon",
                "xkbcommon-x11",
            },
            incdirs = {
                "c/src",
            },
        },
    }
}
