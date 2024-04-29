import criterion

import std/oids
import uuid7
import uuid4

var cfg = newDefaultConfig()

benchmark cfg:
  proc uuid7() {.measure.} =
    discard $initUuid7()

  proc stdOid() {.measure.} =
    discard $genOid()

  proc nimUUID4() {.measure.} =
    discard $uuid4()
