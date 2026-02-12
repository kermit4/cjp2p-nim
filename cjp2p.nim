

# vim: set expandtab shiftwidth=2
import asyncnet, json, net, sets, times, base64, os, tables, sequtils, random
import std/asyncdispatch

type
  Peer = tuple[ip: IpAddress, port: Port]
  Request = object
    offset: int
    peers: HashSet[Peer]
    peer: Peer
    timestamp: float

var
  peers = initHashSet[Peer]()
  requests = initTable[string, Request]()
  peerRequestTime = epochTime() - 20

proc sendRequest(socket: AsyncSocket) {.async.} =
  if peers.len == 0: return
  let peer = peers.toSeq.sample
  let msg = %*[{"PleaseSendPeers": %*{} }]
  await socket.sendTo($peer.ip, peer.port, $msg)

# ... rest of the code ...

proc main() {.async.} =
  randomize()
  let socket = newAsyncSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  socket.bindAddr(Port(24257))

  # add initial peers
  peers.incl((parseIpAddress("148.71.89.128"), Port(24254)))
  peers.incl((parseIpAddress("159.69.54.127"), Port(24254)))

  while true:
    # Check for stalled transfers and retry
    for id, request in requests:
      if epochTime() - request.timestamp > 1:
        echo "retry logic"

    # Request peers periodically
    if epochTime() - peerRequestTime > 10:
      peerRequestTime = epochTime()
      await sendRequest(socket)


    let future = socket.recvFrom(8192)
    let timeout = sleepAsync(1000)
    let winner = waitFor(race(future, timeout))
    if winner == timeout:
      # timeout occurred
      discard
    else:
      let (msg, address, port) = future.read
      if msg != "":
        try:
          let jsonMsg = parseJson(msg)
          # handle message
        except JsonParsingError:
          echo "Error parsing JSON: ", getCurrentExceptionMsg()




waitFor main()

