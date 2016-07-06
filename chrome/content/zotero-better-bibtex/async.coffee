Components.utils.import('resource://gre/modules/Services.jsm')

if Zotero.BetterBibTeX.Five
  Zotero.debug('BBT: deasync active')
  Components.utils.import('resource://services-common/async.js')

Zotero.BetterBibTeX.SQLite =
  db: Zotero.DB

  Set: (values) -> '(' + ('' + v for v in values).join(', ') + ')'

  query: (sql, params = []) ->
    return @db.query(sql, params) unless Zotero.BetterBibTeX.Five

    cb = Async.makeSyncCallback()
    @db.queryAsync(sql, params).then(
      (result) -> cb(result),
      (reason) -> cb.throw(reason)
    )
    return Async.waitForSyncCallback(cb)

  valueQuery: (sql, params) ->
    return @db.valueQuery(sql, params) unless Zotero.BetterBibTeX.Five

    cb = Async.makeSyncCallback()
    @db.valueQueryAsync(sql, params).then(
      (result) -> cb(result),
      (reason) -> cb.throw(reason)
    )
    return Async.waitForSyncCallback(cb)

  columnQuery: (sql, params) ->
    return @db.columnQuery(sql, params) unless Zotero.BetterBibTeX.Five

    cb = Async.makeSyncCallback()
    @db.columnQueryAsync(sql, params).then(
      (result) -> cb(result),
      (reason) -> cb.throw(reason)
    )
    return Async.waitForSyncCallback(cb)
