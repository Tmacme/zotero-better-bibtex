if not Zotero.BetterBibTeX
  loader = Components.classes['@mozilla.org/moz/jssubscript-loader;1'].getService(Components.interfaces.mozIJSSubScriptLoader)

  for script in " lokijs
                  zotero-better-bibtex
                  vardump
                  preferences
                  translators
                  async
                  db
                  csl-localedata
                  fold-to-ascii
                  punycode
                  BetterBibTeXPatternFormatter
                  BetterBibTeXPatternParser
                  preferences
                  keymanager
                  journalAbbrev
                  web-endpoints
                  schomd
                  cayw
                  debug-bridge
                  cache
                  autoexport
                  serialized
                  ".trim().split(/\s+/)
    try
      Zotero.debug("BBT: loading #{script}")
      loader.loadSubScript("chrome://zotero-better-bibtex/content/#{script}.js")
    catch err
      Zotero.debug("BBT: failed to load #{script}; #{err}")
      Zotero.BetterBibTeX = null
      break

  loader = ->
    try
      Zotero.BetterBibTeX.init()
    catch err
      Zotero.debug("BBT: failed to init; #{err}")
    return

  if Zotero.BetterBibTeX.Five
    Zotero.Promise.coroutine(->
      yield Zotero.Schema.schemaUpdatePromise
      loader()
    )()
  else
    window.addEventListener('load', (load = (event) ->
      window.removeEventListener('load', load, false) #remove listener, no longer needed
      loader()
      return
    ), false)
