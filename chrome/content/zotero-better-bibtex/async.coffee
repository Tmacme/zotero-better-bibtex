Components.utils.import('resource://gre/modules/Services.jsm')

Zotero.debug("BBT: deasync, version=#{Zotero.BetterBibTeX.zoteroRelease}, 5=#{Zotero.BetterBibTeX.zoteroRelease[0] == '5'}")
if Zotero.BetterBibTeX.zoteroRelease[0] == '5'
  Zotero.debug('BBT: deasync')
  Components.utils.import('resource://services-common/async.js')
  Zotero.BetterBibTeX.Async = true

class Zotero.BetterBibTeX.SQLite
  db: Zotero.DB

  constructor: (name) ->
    @db = new Zotero.DBConnection(name)

  Set: (values) -> '(' + ('' + v for v in values).join(', ') + ')'

  query: (sql, params = []) ->
    return @db.query(sql, params) unless Zotero.BetterBibTeX.Async

    cb = Async.makeSyncCallback()
    @db.queryAsync(sql, params).then(
      (result) -> cb(result),
      (reason) -> cb.throw(reason)
    )
    return Async.waitForSyncCallback(cb)

  valueQuery: (sql, params) ->
    return @db.valueQuery(sql, params) unless Zotero.BetterBibTeX.Async

    cb = Async.makeSyncCallback()
    @db.valueQueryAsync(sql, params).then(
      (result) -> cb(result),
      (reason) -> cb.throw(reason)
    )
    return Async.waitForSyncCallback(cb)

  columnQuery: (sql, params) ->
    return @db.columnQuery(sql, params) unless Zotero.BetterBibTeX.Async

    cb = Async.makeSyncCallback()
    @db.columnQueryAsync(sql, params).then(
      (result) -> cb(result),
      (reason) -> cb.throw(reason)
    )
    return Async.waitForSyncCallback(cb)
