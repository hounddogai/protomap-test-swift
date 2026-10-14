import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped census segments by code.
    protocol CappedCensusSegmentStore {
        func find(_ code: String) -> CappedCensusSegment?
        func save(_ item: CappedCensusSegment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCensusSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCensusSegmentStore: CappedCensusSegmentStore {
        var items: [String: CappedCensusSegment]
        var order: [String]

        init(items: [String: CappedCensusSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCensusSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCensusSegment) {
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

        func list() -> [CappedCensusSegment] {
            var out: [CappedCensusSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCensusSegmentStore() -> any CappedCensusSegmentStore {
        return MemoryCappedCensusSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCensusSegmentStore: CappedCensusSegmentStore {
        var inner: MemoryCappedCensusSegmentStore
        var cache: TTLCache<CappedCensusSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCensusSegmentStore, cache: TTLCache<CappedCensusSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCensusSegment? {
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

        func save(_ item: CappedCensusSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCensusSegment] {
            return inner.list()
        }
    }

    static func newCachedCappedCensusSegmentStore(_ inner: MemoryCappedCensusSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCensusSegmentStore {
        return CachedCappedCensusSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped census segments. Empty fields match all.
    final class CappedCensusSegmentQuery {
        var channel: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCensusSegment) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCensusSegment]) -> [CappedCensusSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCensusSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCensusSegments(_ store: any CappedCensusSegmentStore, query: CappedCensusSegmentQuery) -> [CappedCensusSegment] {
        return query.apply(store.list())
    }
}
