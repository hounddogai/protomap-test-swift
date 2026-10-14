import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness segments by code.
    protocol WitnessSegmentStore {
        func find(_ code: String) -> WitnessSegment?
        func save(_ item: WitnessSegment)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessSegmentStore: WitnessSegmentStore {
        var items: [String: WitnessSegment]
        var order: [String]

        init(items: [String: WitnessSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessSegment) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [WitnessSegment] {
            var out: [WitnessSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessSegmentStore() -> any WitnessSegmentStore {
        return MemoryWitnessSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessSegmentStore: WitnessSegmentStore {
        var inner: MemoryWitnessSegmentStore
        var cache: TTLCache<WitnessSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessSegmentStore, cache: TTLCache<WitnessSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessSegment? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: WitnessSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessSegment] {
            return inner.list()
        }
    }

    static func newCachedWitnessSegmentStore(_ inner: MemoryWitnessSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessSegmentStore {
        return CachedWitnessSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness segments. Empty fields match all.
    final class WitnessSegmentQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessSegment]) -> [WitnessSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessSegments(_ store: any WitnessSegmentStore, query: WitnessSegmentQuery) -> [WitnessSegment] {
        return query.apply(store.list())
    }
}
