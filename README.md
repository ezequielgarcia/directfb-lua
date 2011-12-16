Overview
========

directfb-lua [Lua](http://www.lua.org) binding to [DirectFB](http://directfb.org).
It is an automated binding generated from the DirectFB headers.

For more info, contact me:
 * Ezequiel Garcia elezegarcia@gmail.com

Support
-------

So far the supported interfaces are:
 * IDirectFB
 * IDirectFBSurface
 * IDirectFBDisplayLayer
 * IDirectFBWindow
 * IDirectFBImageProvider
 * IDirectFBFont

The rest is still not supported, but the plan is to support (almost) everything.
Since Lua is not a low-level language there won't be (at least for now) support 
for low level buffer handling, for instance Surface::Lock().

History
-------

## directfb-lua 0.1

* Public alpha, basic functionality provided: font rendering, image rendering, window management, basic surface stuff.

Building
--------

You will need:

* Lua 5.1
* Perl 5.12
* DirectFB headers

You can get the latest source of directfb-lua from https://github.com/ezequielgarcia/directfb-lua
using:

    git clone git://github.com/ezequielgarcia/directfb-lua.git

The sources are generated with:

    make gen

And the library is compiled with:

    make

This will create directfb.so library wich you can copy to your `LUA_CPATH`.

Usage
-----

A quick example with font and image rendering:

    require 'directfb'

    -- DFB Initialization
    directfb.DirectFBInit()
    dfb = directfb.DirectFBCreate()
    dfb:SetCooperativeLevel(DFSCL_EXCLUSIVE)

    -- Surface creation, notice the SUM instead of OR
    desc = {}
    desc.flags = DSDESC_CAPS
    desc.caps = DSCAPS_PRIMARY + DSCAPS_FLIPPING

    surface = dfb:CreateSurface(desc)
	surface:Clear( 0x80, 0x80, 0x80, 0xff )

    -- Font creation
    font_path = '/usr/share/fonts/TTF/DejaVuSans.ttf'
    font = dfb:CreateFont(font_path, {flags=DFDESC_HEIGHT, height=30})

    surface:SetFont(font)

    -- Image creation
    image = dfb:CreateImageProvider('lua.gif')
    image_surf = dfb:CreateSurface(image:GetSurfaceDescription())
    image:RenderTo(image_surf, nil)

	surface:Blit(image_surf, nil, 100, 100)
	surface:SetColor(0, 0, 0, 0xff)
	surface:DrawString('DirectFB meets Lua', -1, 10, 10, DSTF_TOPLEFT)

	surface:Flip(nil, 0)

    image:Release()
    font:Release()
    image_surf:Release()
    surface:Release()
    dfb:Release()

Another example with a couple of windows:

    require 'directfb'

    -- DFB Initialization
    directfb.DirectFBInit()
    dfb = directfb.DirectFBCreate()
    dfb:SetCooperativeLevel(DFSCL_FULLSCREEN)

    -- Get layer
    layer = dfb:GetDisplayLayer()

    -- Create window
    desc = {}
    desc.flags = DWDESC_WIDTH + DWDESC_HEIGHT + DWDESC_SURFACE_CAPS
    desc.width = 100
    desc.height = 100
    desc.surface_caps = DSCAPS_FLIPPING
    w1 = layer:CreateWindow(desc)
    w2 = layer:CreateWindow(desc)

    -- Get windows surface
    s1 = w1:GetSurface()
    s2 = w2:GetSurface()
 
    s1:Clear( 0xff, 0, 0, 0xff)
    s2:Clear( 0, 0xff, 0, 0xff)

    w1:MoveTo(100, 100)
    w2:MoveTo(150, 150)

    w1:SetOpacity(0x80)
    w2:SetOpacity(0x80)

	s1:Release()
	s2:Release()
	w1:Release()
	w2:Release()
	layer:Release()
	dfb:Release()

License
-------

Copyright (c) 2011 Ezequiel Garcia

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
