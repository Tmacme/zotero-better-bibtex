bluebird = require('bluebird')

Async = new class
  x: 1

  y: bluebird.coroutine(->
    console.log('y:', @x)
    return yield bluebird.resolve(@x + 1)
  )

  z: bluebird.coroutine(->
    v = yield @y()
    console.log('z:', v)
    return bluebird.resolve(v)
  )

Async.z().then((v) -> console.log(v))
