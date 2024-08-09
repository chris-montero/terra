# Terra
*What if you didn't have to write electron apps anymore?*

Terra offers a platform-independent, featureful toolkit that allows you to easily and quickly build your application, and then flexibly go as low-level as you need to optimize your application.  
This toolkit was built based on my experience with [AwesomeWM](https://github.com/awesomeWM/awesome), [Elm](https://elm-lang.org/), and [Elm-ui](https://github.com/mdgriffith/elm-ui), and other projects. I hope you find it useful.
<p align="center"><img src="https://github.com/chris-montero/terra/blob/master/showcase/whether.png?raw=true" alt="Whether weather app image"></p>

## Build beautiful applications
Terra aims to make developing cross platform applications an experience that is both fast and pleasant, without sacrificing on aesthetics or performance. 
<p align="center"><img src="https://github.com/chris-montero/terra/blob/master/showcase/mathgraph.png?raw=true" alt="Mathgraph app image"></p>

## Current state
**Warning: Terra is still very early in development. We push to the main branch and live life day to day.**  
Terra currently only works with luajit on linux under Xorg. Support for Wayland, Windows and Mac is planned.  
If you experience any issues with installing, bugs, etc., you can open an issue or contact me directly.

## Example
This code creates an application, creates a window, creates a UI tree with Oak, terra's built-in UI library, paints a green background, creates a red ball, draws "hello world" on it, and animates the ball to spin in a circle.
```lua
#!/usr/bin/env luajit

local t_app = require("terra.app")
local t_window = require("terra.window." .. t_app.get_platform())

local tt_color = require("terra.tools.color")

local to_size = require("terra.oak.size")
local to_align = require("terra.oak.align")

local toeb_root = require("terra.oak.elements.branches.root")
local toeb_el = require("terra.oak.elements.branches.el")

local toel_bg = require("terra.oak.elements.leaves.bg")
local toel_text = require("terra.oak.elements.leaves.text")

local function init_app(app)

    local model = {}
    app.model = model

    -- create the window
    model.main_window = t_window.create(app, 320, 420, 200, 160, {

        tree = toeb_root.new({ -- the root of the UI tree
            toeb_el.new({ -- the background of the window
                width = to_size.FILL,
                height = to_size.FILL,
                bg = toel_bg.new({
                    source = tt_color.rgb(0.17, 0.42, 0.21), -- green
                }),
                toeb_el.new({ -- the red ball
                    halign = to_align.CENTER,
                    valign = to_align.CENTER,
                    width = 60,
                    height = 60,
                    bg = toel_bg.new({
                        source = tt_color.rgb(0.8, 0.1, 0), -- red
                        border_radius = 30,
                    }),
                    -- declaratively subscribe to signals on elements
                    subscribe_on_root = { 
                        ["AnimationEvent"] = function(self, time)
                            local spin_push = 20
                            self:set_offset_x(math.sin(time) * spin_push)
                            self:set_offset_y(-math.cos(time) * spin_push)
                        end
                    },
                    toel_text.new({ -- the "hello" text
                        family = "Roboto",
                        size = 11,
                        width = 40, -- constrain the textbox so the text wraps
                        halign = to_align.CENTER,
                        valign = to_align.CENTER,
                        text = "hello world",
                        fg = tt_color.rgb(1, 1, 1),
                    })
                }),
            }),
        }),
    })

    t_window.request_raise(model.main_window)
end

t_app.desktop(init_app, t_app.make_default_event_handler(function(app, event_type, ...)
end))
```

The above code produces the following output:
<p align="center"><img src="https://github.com/chris-montero/terra/blob/master/showcase/green_background_red_ball.png?raw=true" alt="green background red ball image"></p>

## Installing
1. Clone the repo  
`git clone https://github.com/chris-montero/terra`
2. Build the project and install the luarock  
`sudo luarocks make`
3. That's it. Now you should be able to successfully run the code in the [Example](#Example) section.

# Credits
* [Uli Schlachter](https://github.com/psychon), for promptly and elaborately answering my questions on about Xorg on stack overflow.
* My mom, for sponsoring this project. Thanks mom.

# Contributing
You are welcome to contribute by opening issues, comitting code, or donations.

https://ko-fi.com/chrismontero

US DOLLAR IBAN: `RO75BTRLUSDCRT0323524101`  
EURO IBAN: `RO71BTRLEURCRT0323524101`
