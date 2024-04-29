from std/random import initRand, next
from std/times import Time, getTime, toUnix, nanosecond

#[

  ## Resources: 
  - https://github.com/uuid-rs/uuid/blob/main/src/v7.rs

]#

type Uuid* = array[16, uint8]

const hexEncTab =
  ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

proc `$`*(uuid: Uuid): string =
  ## uuid to string 
  ##
  runnableExamples:
    block:
      let uuid7 = initUuid7()
      echo $uuid7

  var s = newStringOfCap(36)
  var i = 0
  for b in uuid:
    s.add hexEncTab[(b shr 4 and 0x0f).int]
    s.add hexEncTab[(b and 0x0f).int]
    inc i
    if i in [4, 6, 8]:
      s.add '-'
  result = s

# 4-2-2-8
#
proc fromFields*(
    d1: uint32, d2: uint16, d3: uint16, d4: array[8, uint8]
): Uuid {.inline.} =
  [
    (d1 shr 24).uint8,
    (d1 shr 16).uint8,
    (d1 shr 8).uint8,
    d1.uint8,
    (d2 shr 8).uint8,
    d2.uint8,
    (d3 shr 8).uint8,
    d3.uint8,
    d4[0],
    d4[1],
    d4[2],
    d4[3],
    d4[4],
    d4[5],
    d4[6],
    d4[7],
  ]

proc encode_unix_timestamp_millis(
    millis: uint64, random_bytes: array[10, uint8]
): Uuid {.inline.} =
  let millis_high = ((millis shr 16) and 0xFFFF_FFFF'u64).uint32
  let millis_low = (millis and 0xFFFF).uint16

  let random_and_version =
    (random_bytes[1].uint16 or ((random_bytes[0].uint16) shl 8) and 0x0FFF) or
    (0x7 shl 12)

  var d4: array[8, uint8]

  d4[0] = (random_bytes[2] and 0x3F) or 0x80
  d4[1] = random_bytes[3]
  d4[2] = random_bytes[4]
  d4[3] = random_bytes[5]
  d4[4] = random_bytes[6]
  d4[5] = random_bytes[7]
  d4[6] = random_bytes[8]
  d4[7] = random_bytes[9]

  result = fromFields(millis_high, millis_low, random_and_version, d4)

proc `|+|`(a, b: int64): int64 {.inline.} =
  ## saturated addition.
  ## https://github.com/nim-lang/Nim/blob/fcb8461efab2ef7bdd976f82af8c7d1390f502ac/compiler/saturate.nim#L12
  ##
  result = a +% b
  if (result xor a) >= 0'i64 or (result xor b) >= 0'i64:
    return result
  if a < 0 or b < 0:
    result = low(typeof(result))
  else:
    result = high(typeof(result))

var rand = initRand()

proc initUuid7*(ts: Time = getTime()): Uuid =
  ## init uuid7
  ##
  runnableExamples:
    block:
      let uuid7 = initUuid7()
      echo $uuid7

  let secs = ts.toUnix()
  let nsecs = ts.nanosecond
  let millis = ((secs * 1000) |+| (nsecs.int64 div 1_000_000)).uint64

  var rand_bytes: array[10, uint8]
  for b in rand_bytes.mitems():
    b = rand.next().uint8

  encode_unix_timestamp_millis(millis, rand_bytes)
