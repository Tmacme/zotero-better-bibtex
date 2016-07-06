#window.addEventListener('load', ->
#  ZoteroItemPane.addCitekeyRow()
#
#  observer = new MutationObserver((mutations) ->
#    ZoteroItemPane.addCitekeyRow()
#
#    itembox = document.getElementById('zotero-editpane-item-box')
#    display = document.getElementById('zotero-better-bibtex-itempane-citekey')
#    if display && itembox && itembox.item
#      citekey = Zotero.BetterBibTeX.keymanager.get(itembox.item)
#      if citekey
#        display.value = citekey.citekey
#        display.classList[if citekey.citekeyFormat then 'add' else 'remove']('citekey-dynamic')
#      else
#        display.value = ''
#        Zotero.BetterBibTeX.log("#{item.itemTypeID} has no citekey")
#  )
#  observer.observe(document.getElementById('dynamic-fields'), {childList: true})
#  return
#)
#
#ZoteroItemPane.addCitekeyRow = ->
#  id = 'zotero-better-bibtex-itempane-citekey'
#  if document.getElementById(id)
#    console.log("#{id} already present")
#    return
#  console.log("creating #{id}")
#
#  template = document.getElementById('zotero-better-bibtex-itempane-citekey-template')
#
#  label = template.firstElementChild.cloneNode(true)
#  value = template.lastElementChild.cloneNode(true)
#  value.id = 'zotero-better-bibtex-itempane-citekey'
#
#  row = document.createElement('row')
#  row.appendChild(label)
#  row.appendChild(value)
#
#  fields = document.getElementById('dynamic-fields')
#  if fields.childNodes.length > 1
#    console.log("inserting #{id}")
#    fields.insertBefore(row, fields.childNodes[1])
#  else
#    console.log("adding #{id}")
#    fields.appendChild(row)
#
#ZoteroItemPane.viewItem = ((original) ->
#  return (item, mode, index) ->
#    original.apply(@, arguments)
#    if index == 0 # details pane
#      ZoteroItemPane.addCitekeyRow()
#      display = document.getElementById('zotero-better-bibtex-itempane-citekey')
#      citekey = Zotero.BetterBibTeX.keymanager.get(item)
#      if citekey
#        display.value = citekey.citekey
#        display.classList[if citekey.citekeyFormat then 'add' else 'remove']('citekey-dynamic')
#      else
#        display.value = ''
#        Zotero.BetterBibTeX.log("#{item.itemTypeID} has no citekey") unless citekey
#  )(ZoteroItemPane.viewItem)
