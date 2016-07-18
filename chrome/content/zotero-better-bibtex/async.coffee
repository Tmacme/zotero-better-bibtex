Components.utils.import('resource://gre/modules/Services.jsm')

if Zotero.BetterBibTeX.Five
  Zotero.debug('BBT: deasync active')
  Components.utils.import('resource://services-common/async.js')
  Zotero.BetterBibTeX.deasync = (object, method, args...) ->
    cb = Async.makeSyncCallback()
    object[method].bind(object).apply(null, args).then(
      (result) -> cb(result),
      (reason) -> cb.throw(reason)
    )
    return Async.waitForSyncCallback(cb)

Zotero.BetterBibTeX.SQLite =
  db: Zotero.DB

  Set: (values) -> '(' + ('' + v for v in values).join(', ') + ')'

  query: (sql, params = []) ->
    return @db.query(sql, params) unless Zotero.BetterBibTeX.Five

    return Zotero.BetterBibTeX.deasync(@db, 'queryAsync', sql, params)

  valueQuery: (sql, params) ->
    return @db.valueQuery(sql, params) unless Zotero.BetterBibTeX.Five

    return Zotero.BetterBibTeX.deasync(@db, 'valueQueryAsync', sql, params)

  columnQuery: (sql, params) ->
    return @db.columnQuery(sql, params) unless Zotero.BetterBibTeX.Five

    return Zotero.BetterBibTeX.deasync(@db, 'columnQueryAsync', sql, params)

Zotero.BetterBibTeX.Translators ?= {}

Zotero.BetterBibTeX.Translators.init = ->
  return unless Zotero.BetterBibTeX.Five
  return Zotero.BetterBibTeX.deasync(Zotero.Translators, 'init')

Zotero.BetterBibTeX.Translators.reinit = ->
  return Zotero.Translators.init() unless Zotero.BetterBibTeX.Five
  return Zotero.BetterBibTeX.deasync(Zotero.Translators, 'reinit')
