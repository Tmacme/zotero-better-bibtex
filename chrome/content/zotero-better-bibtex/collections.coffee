Zotero.BetterBibTeX.Collections = new class
  constructor: ->
    @reload()

  reload: ->
    @parent = {}
    @items = {}

    for coll in Zotero.DB.query('select collectionID, parentCollectionID from collections')
      if coll.parentCollectionID?
        @parent[parseInt(coll.parentCollectionID)] = parseInt(coll.collectionID)

    for item in Zotero.DB.query('select itemID, collectionID from collectionItems')
      itemID = parseInt(item.itemID)
      collectionID = parseInt(item.collectionID)
      @items[itemID] ||= {}
      @items[itemID][collectionID] = collectionID

  remove: (itemID) ->
    return unless itemID?
    delete @items[parseInt(itemID)]

  affectedBy: (itemIDs) ->
    itemIDs = [itemIDs] unless Array.isArray(itemIDs)
    affected = {}
    for itemID in itemIDs
      for collectionID of @items[parseInt(itemID)] || {}
        @expand(affected, collectionID)
    return Object.keys(affected)

  expand: (affected, collectionID) ->
    affected[collectionID] = true
    @expand(affected, @parent[collectionID]) if @parent[collectionID]?
