Zotero.BetterBibTeX.auto = new class
  constructor: ->
    @db = Zotero.BetterBibTeX.DB
    @search = {}
    @idle = false

    for ae in @db.autoexport.data
      if ae.status == 'running'
        ae.status = 'pending'
        @db.autoexport.update(ae)

  mark: (ae, status, reason) ->
    Zotero.BetterBibTeX.debug('mark:', {ae, status})
    ae.updated = (new Date()).toLocaleString()
    ae.status = status
    @db.autoexport.update(ae)

    @schedule(reason || 'no reason provided') if status == 'pending'

  markSearch: (id, reason) ->
    search = Zotero.Searches.get(id)
    return false unless search

    items = (parseInt(itemID) for itemID in search.search())
    items.sort()
    return if items == @search[parseInt(search.id)]

    @search[parseInt(search.id)] = items

    ae = @db.autoexport.findObject({collection: "search:#{id}"})
    @mark(ae, 'pending', reason) if ae

  updated: ->
    wm = Components.classes['@mozilla.org/appshell/window-mediator;1'].getService(Components.interfaces.nsIWindowMediator)
    enumerator = wm.getEnumerator('zotero:pref')
    if enumerator.hasMoreElements()
      win = enumerator.getNext()
      win.BetterBibTeXAutoExportPref.refresh(true)

  add: (collection, path, context) ->
    Zotero.BetterBibTeX.debug("auto-export set up for #{collection} to #{path}")

    @db.autoexport.removeWhere({path})

    @db.autoexport.insert({
      collection
      path
      translatorID: context.translatorID
      exportCharset: (context.exportCharset || 'UTF-8').toUpperCase()
      exportNotes: !!context.exportNotes
      useJournalAbbreviation: !!context.useJournalAbbreviation
      status: 'done'
      updated: (new Date()).toLocaleString()
    })
    @updated()
    @db.save('main')

  markIDs: (ids, reason) ->
    collections = Zotero.Collections.getCollectionsContainingItems(ids, true) || []
    collections = @withParentCollections(collections) unless collections.length == 0
    collections = ("collection:#{id}" for id in collections)
    for libraryID in Zotero.BetterBibTeX.SQLite.columnQuery("select distinct libraryID as libraryID from items where itemID in #{Zotero.BetterBibTeX.SQLite.Set(ids)}")
      if libraryID
        collections.push("library:#{libraryID}")
      else
        collections.push('library')

    for ae in @db.autoexport.where((o) -> o.collection.indexOf('search:') == 0)
      @markSearch(ae.collection.replace('search:', ''), "#{reason}, assume search might be updated")

    if collections.length > 0
      Zotero.BetterBibTeX.debug('marking:', collections, 'from', (o.collection for o in @db.autoexport.data))
      for ae in @db.autoexport.where((o) -> o.collection in collections)
        @mark(ae, 'pending', reason)

  withParentCollections: (collections) ->
    return collections if collections.length == 0

    return Zotero.BetterBibTeX.SQLite.columnQuery("
      with recursive recursivecollections as (
        select collectionID, parentCollectionID
        from collections
        where collectionID in #{Zotero.BetterBibTeX.SQLite.Set(collections)}

        union all

        select p.collectionID, p.parentCollectionID
        from collections p
        join recursivecollections as c on c.parentCollectionID = p.collectionID
      ) select distinct collectionID as collectionID from recursivecollections")

  clear: ->
    @db.autoexport.removeDataOnly()
    @updated()

  reset: ->
    for ae in @db.autoexport.data
      @mark(ae, 'pending', 'reset')
    @updated()

  prepare: (ae) ->
    Zotero.BetterBibTeX.debug('auto.prepare: candidate', ae)
    path = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile)
    path.initWithPath(ae.path)

    switch
      when path.exists() && (!path.isFile() || !path.isWritable())
        error = "auto.prepare: candidate path '#{ae.path}' exists but is not writable"

      when path.parent.exists() && !path.parent.isWritable()
        error = "auto.prepare: parent of candidate path '#{ae.path}' exists but is not writable"

      when !path.parent.exists()
        error = "auto.prepare: parent of candidate path '#{ae.path}' does not exist"

      else
        error = null

    if error
      Zotero.BetterBibTeX.debug(msg)
      @mark(ae, 'error')
      throw new Error(msg)

    switch
      when ae.collection == 'library'
        items = {library: null}

      when m = /^search:([0-9]+)$/.exec(ae.collection)
        ### assumes that a markSearch will have executed the search and found the items ###
        items = {items: @search[parseInt(m[1])] || []}
        if items.items.length == 0
          Zotero.BetterBibTeX.debug('auto.prepare: empty search')
          return null
        else
          items.items = Zotero.Items.get(items.items)

      when m = /^library:([0-9]+)$/.exec(ae.collection)
        items = {library: parseInt(m[1])}

      when m = /^collection:([0-9]+)$/.exec(ae.collection)
        items = {collection: parseInt(m[1])}

      else #??
        Zotero.BetterBibTeX.debug('auto.prepare: unexpected collection id ', ae.collection)
        return null

    if items.items && items.items.length == 0
      Zotero.BetterBibTeX.debug('auto.prepare: candidate ', ae.path, ' has no items')
      return null

    translation = new Zotero.Translate.Export()

    for own k, v of items
      switch k
        when 'items'
          Zotero.BetterBibTeX.debug('preparing auto-export from', items.length, 'items')
          translation.setItems(items.items)
        when 'collection'
          Zotero.BetterBibTeX.debug('preparing auto-export from collection', items.collection)
          translation.setCollection(Zotero.Collections.get(items.collection))
        when 'library'
          Zotero.BetterBibTeX.debug('preparing auto-export from library', items.library)
          translation.setLibraryID(items.library)

    translation.setLocation(path)
    translation.setTranslator(ae.translatorID)

    translation.setDisplayOptions({
      exportCharset: ae.exportCharset
      exportNotes: ae.exportNotes
      useJournalAbbreviation: ae.useJournalAbbreviation
    })

    return translation

  schedule: (reason) ->
    #if Zotero.Sync.Server.syncInProgress || Zotero.Sync.Storage.syncInProgress
    #  Zotero.BetterBibTeX.debug('auto.delay:', reason)
    #  clearTimeout(@delayed) if @delayed
    #  @delayed = setTimeout(->
    #    Zotero.BetterBibTeX.auto.delayed = null
    #    Zotero.BetterBibTeX.auto.schedule(reason)
    #  , 5000)
    #  return

    Zotero.BetterBibTeX.debug('auto.schedule:', reason)
    clearTimeout(@scheduled) if @scheduled
    @scheduled = setTimeout(->
      Zotero.BetterBibTeX.auto.scheduled = null
      Zotero.BetterBibTeX.auto.process(reason)
    , 1000)

  process: (reason) ->
    Zotero.BetterBibTeX.debug("auto.process: started (#{reason}), idle: #{@idle}")

    if @running
      Zotero.BetterBibTeX.debug('auto.process: export already running')
      return

    switch Zotero.BetterBibTeX.Pref.get('autoExport')
      when 'off'
        Zotero.BetterBibTeX.debug('auto.process: off')
        return
      when 'idle'
        if !@idle
          Zotero.BetterBibTeX.debug('auto.process: not idle')
          return

    skip = {error: [], done: []}
    translation = null

    for ae in @db.autoexport.findObjects({status: 'pending'})
      try
        translation = @prepare(ae)
      catch err
        Zotero.BetterBibTeX.debug('auto.process:', err)
        continue

      if !translation
        @mark(ae, 'done')
      else
        break

    if translation
      @running = '' + ae.$loki
    else
      Zotero.BetterBibTeX.debug('auto.process: no pending jobs')
      return

    Zotero.BetterBibTeX.debug('auto.process: starting', ae)
    @mark(ae, 'running')
    @updated()

    translation.setHandler('done', (obj, worked) =>
      running = @db.autoexport.get(ae.$loki)

      ### could have been re-marked for export before this one was done ###
      if running.status == 'running'
        status = (if worked then 'done' else 'error')
        Zotero.BetterBibTeX.debug("auto.process: finished #{Zotero.BetterBibTeX.auto.running}: #{status}")
        @mark(ae, status)
      else
        Zotero.BetterBibTeX.debug("auto.process: #{ae.$loki} was re-marked to #{running.status} before it finished")
      Zotero.BetterBibTeX.auto.running = null
      Zotero.BetterBibTeX.auto.updated()
      Zotero.BetterBibTeX.auto.process(reason)
    )
    translation.translate()
