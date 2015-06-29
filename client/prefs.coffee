# Preferences API -- localStorage should be accessed only through it
#   Only ../init-nw.coffee bypasses this API because it can't require() it.
# Usage:
#   prefs.foo()                 # getter
#   prefs.foo(123)              # setter
#   prefs.foo (newValue) -> ... # add "on change" listener
#   prefs.foo.toggle()          # convenience function for booleans (numbers 0 and 1)
#   prefs.foo.getDefault()      # retrieve default value
prefs = @
[ # name                    default (type is determined from default value; setter enforces type and handles encoding)
  ['favs',                  [host: '127.0.0.1', port: 4502]]
  ['floating',              0] # floating editor and tracer windows
  ['floatOnTop',            0] # try to keep floating windows on top of the session
  ['kbdLocale',             ''] # e.g. "US", "GB"
  ['lineNumsTracer',        0]
  ['lineNumsEditor',        1]
  ['menu',                  '''
    # _x   access key, alt+x
    # =CMD command code; some are special:
    #        LBR FLT WRP TOP render as checkboxes
    #        THM ("Theme") renders its own submenu
    # =http://example.com/  open a URL
    # {}   conditional display, a boolean expression
    #        operators: && || ! ( )
    #        variables: browser mac
    # -    separator (when alone)
    # #    comment
    Dyalog                          {mac}
      About Dyalog             =ABT
      -
      Preferences              =PRF
    _File                           {!browser}
      New _Session             =NEW
      _Connect...              =CNC
      -                             {!mac}
      _Quit                    =QIT {!mac}
    _Edit
      Cut                      =CUT {!mac&&!browser}
      Copy                     =CPY {!mac&&!browser}
      Paste                    =PST {!mac&&!browser}
      Undo                     =UND {!mac&&!browser}
      Redo                     =RDO {!mac&&!browser}
      -                             {!mac&&!browser}
      Preferences              =PRF {!mac}
      Select All               =selectAll {mac}
    _View
      Show Language Bar        =LBR
      Float New Editors        =FLT
      Editors on Top           =TOP {!browser}
      Line Wrapping in Session =WRP
      -                             {!browser}
      Increase Font Size       =ZMI {!browser}
      Decrease Font Size       =ZMO {!browser}
      Reset Font Size          =ZMR {!browser}
      -
      Theme                    =THM
    _Actions
      Weak Interrupt           =WI
      Strong Interrupt         =SI
    _Window                         {mac}
    _Help
      About                    =ABT {!mac}
      -                             {!mac}
      Dyalog Help              =http://help.dyalog.com/
      Documentation Centre     =http://dyalog.com/documentation.htm
      -
      Dyalog Website           =http://dyalog.com/
      MyDyalog                 =https://my.dyalog.com/
      -
      Dyalog Forum             =http://www.dyalog.com/forum
  ''']
  ['pos',                   null] # [x,y,w,h] of the main window, used in ../init-nw.coffee
  ['posEditor',             [32, 32, 1000, 618]] # [x,y,w,h]
  ['posTracer',             [32, 32, 1000, 618]] # [x,y,w,h]
  ['prefixKey',             '`']
  ['prefixMap',             ''] # pairs of characters; only differences from the default ` map are stored
  ['wrap',                  0] # line wrapping in session
  ['lbar',                  1] # show language bar
  ['theme',                 '']
  ['title',                 '{WSID} - {HOST}:{PORT} (PID: {PID})'] # a.k.a. "caption"
  ['zoom',                  0]
]
.forEach ([k, d]) ->       # k: preference name, d: default value
  t = typeof d; l = []     # t: type, l: listeners
  str = if t == 'object' then JSON.stringify else (x) -> '' + x
  sd = str d               # sd: default value "d" converted to a string
  prefs[k] = p = (x) ->
    if typeof x == 'function'
      l.push x; return
    else if arguments.length
      if t == 'number' then x = +x else if t == 'string' then x = '' + x # coerce to type "t"
      sx = str x # sx: "x" converted to a string; localStorage values can only be strings
      if l.length then old = prefs[k]()
      if sx == sd then delete localStorage[k] else localStorage[k] = sx # avoid recording if it's at its default
      for f in l then f x, old # notify listeners
      x
    else
      if !(r = localStorage[k])? then d
      else if t == 'number' then +r
      else if t == 'object' then JSON.parse r
      else r
  p.getDefault = -> d
  p.toggle = -> p !p()
  return
