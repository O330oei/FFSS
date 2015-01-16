Dyalog.Session = (e, opts = {}) ->

  # keep track of which lines have been modified and preserve the original content
  mod = {} # line number -> original content

  hist = [null]
  histIndex = 0
  histAdd = (lines) -> hist = [null].concat lines, hist[1..]
  histMove = (d) ->
    i = histIndex + d
    if i < 0 then $.alert 'There is no next line', 'Dyalog APL Error'
    else if i >= hist.length then $.alert 'There is no previous line', 'Dyalog APL Error'
    else
      l = cm.getCursor().line
      if !histIndex then hist[0] = cm.getLine l
      cm.replaceRange hist[i], {line: l, ch: 0}, {line: l, ch: cm.getLine(l).length}, 'Dyalog'
      histIndex = i
    return

  k = # extra keys for CodeMirror
    Tab: -> c = cm.getCursor(); opts.autocomplete? cm.getLine(c.line), c.ch
    Enter: -> exec 0
    'Ctrl-Enter': -> exec 1

  k["'\uf828'"] = k['Shift-Enter'] = -> c = cm.getCursor(); opts.edit?(cm.getLine(c.line), c.ch) # ED: Edit
  k["'\uf820'"] = k['Shift-Ctrl-Backspace'] = -> histMove 1 # BK: Backward or Undo
  k["'\uf81f'"] = k['Shift-Ctrl-Enter'] = -> histMove -1 # FD: Forward or Redo

  k["'\uf800'"] = k['Shift-Esc'] = # QT: Quit (and lose changes)
    k["'\uf804'"] = k.Esc = ->     # EP: Exit (and save changes)
      c = cm.getCursor(); l = c.line
      if mod[l]?
        cm.replaceRange mod[l], {line: l, ch: 0}, {line: l, ch: cm.getLine(l).length}, 'Dyalog'
        delete mod[l]; cm.removeLineClass l, 'background', 'modified'; cm.setCursor l + 1, c.ch
      return

  cm = CodeMirror ($e = $ e)[0],
    autofocus: true, mode: '', matchBrackets: true, autoCloseBrackets: true, keyMap: 'dyalog', readOnly: true, extraKeys: k

  exec = (trace) ->
    a = [] # pairs of [lineNumber, contentToExecute]
    for l, s of mod # l: line number, s: original content
      l = +l
      cm.removeLineClass l, 'background', 'modified'
      a.push [l, (e = cm.getLine l)]
      cm.replaceRange s, {line: l, ch: 0}, {line: l, ch: e.length}, 'Dyalog'
    if !a.length then a = [[(l = cm.getCursor().line), cm.getLine l]]
    a.sort (x, y) -> x[0] - y[0]
    opts.exec? (es = for [l, e] in a then e), trace
    histAdd es
    mod = {}

  cm.on 'beforeChange', (_, c) ->
    if c.origin != 'Dyalog'
      if (l = c.from.line) != c.to.line
        c.cancel()
      else
        mod[l] ?= cm.getLine l
        cm.addLineClass l, 'background', 'modified'
    return

  add: (s) ->
    l = cm.lineCount() - 1
    cm.replaceRange s, {line: l, ch: 0}, {line: l, ch: cm.getLine(l).length}, 'Dyalog'
    cm.setCursor cm.lineCount() - 1, 0

  set: (s) ->
    l = cm.lineCount() - 1
    cm.replaceRange s, {line: 0, ch: 0}, {line: l, ch: cm.getLine(l).length}, 'Dyalog'
    cm.setCursor cm.lineCount() - 1, 0

  noPrompt: ->
    cm.setOption 'readOnly', true
    cm.setOption 'cursorHeight', 0
    return

  prompt: (why) -> # 0=Invalid 1=Descalc 2=QuadInput 3=LineEditor 4=QuoteQuadInput 5=Prompt
    cm.setOption 'readOnly', false
    cm.setOption 'cursorHeight', 1
    l = cm.lineCount() - 1
    if (why == 1 && !mod[l]) || why !in [1, 4]
      cm.replaceRange '      ', {line: l, ch: 0}, {line: l, ch: cm.getLine(l).length}, 'Dyalog'
    cm.setCursor l, cm.getLine(l).length
    return

  updateSize: -> cm.setSize $e.width(), $e.height()
  hasFocus: -> cm.hasFocus()
  focus: -> cm.focus()
  insert: (ch) -> c = cm.getCursor(); cm.replaceRange ch, c, c, 'Dyalog'
  scrollCursorIntoView: -> setTimeout (-> cm.scrollIntoView cm.getCursor()), 1
  autocomplete: (skip, options) ->
    c = cm.getCursor(); from = line: c.line, ch: c.ch - skip
    cm.showHint
      completeOnSingleClick: true
      extraKeys: Right: (cm, m) -> m.pick()
      hint: ->
        to = cm.getCursor(); u = cm.getLine(from.line)[from.ch...to.ch].toLowerCase() # u: completion prefix
        {from, to, list: options.filter (o) -> o[...u.length].toLowerCase() == u}
    return
