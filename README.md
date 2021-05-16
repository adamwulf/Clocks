# Clocks

`Clocks` is a package containing different monotonically increasing clocks for use in distributed systems. These are often
used when building CRDTs (Conflict-free Replicating Data Type).

# Reference

Each `Clock` represents a moment in time and is immutable. Instantiate a new clock to represent the starting moment of the system. Call `tick()`
to increment the clock and record the resulting `Clock` along with the event, and store it as the new local clock.

```swift
// track one clock per local event
let start = LamportClock() // or `HybridLogicalClock()` or `VectorClock()`
let event1 = start.tick()
let event2 = event1.tick()
let event3 = event2.tick()

// other nodes send in their (clock, event) pairs for us to synchronize with
let clockFromPeer = LamportClock()

// sync our clock with their clock
let event4 = event3.tock(other: clockFromPeer)

// our next event will be after all of our events _and_ all of the heard incoming events so far
let event5 = event4.tick()

```


# Definitions

## Lamport Clock

These are the simplest clock of those provided. They simply track a monotonically increasing counter. Whenever
an event occurs, increase the counter by 1. Whenever syncing with another clock, increment above the max
of the current value and the seen value.

In this way, every event seen either locally or sent by a peer can be ordered relative to all other events. In the case
of a tie, the sorting the clocks' identifier will break the tie.

## Vector Clock

A vector clock implementation will have each node in the network keep its own clock. Each clock will have keep a counter
that will monotonically increase whenever a local event occurs. Whenever an event is sent to other peers, the entire clock is sent.
Similarly, whenever an event is heard from a peer, their entire clock (and any clocks that peer has heard of) are received. The count
for each clock that's been heard of is set to the max value that's been seen so far.

An event can be said to be _before_ another event if and only if all of the counts in one clock are less than or equal to (with at least one
less than) the other clock.

## Hybrid Logical Clock

A hybrid logical clock uses a combination of a timestamp and a counter to define a unique point in time. The clock tracks the last
seen realworld timestamp along with a clock count. If the current timestamp is after the stored timestamp, then the timestamp is updated
and the count is set to zero. otherwise, the timestamp is left unchanged and the count is incremented.

In this way, each time an event occurs, either the timestamp is increased or the count is increased. This allows all local events to be ordered
uniquely with all events heard from peers. When sending events, all nodes will agree on the exact ordering of all heard events.

## References

1. https://miafish.wordpress.com/2015/03/11/lamport-vector-clocks/
2. https://jaredforsyth.com/posts/hybrid-logical-clocks/
