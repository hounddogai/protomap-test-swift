import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure segments by code.
    protocol ClosureSegmentStore {
        func find(_ code: String) -> ClosureSegment?
        func save(_ item: ClosureSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureSegmentStore: ClosureSegmentStore {
        var items: [String: ClosureSegment]
        var order: [String]

        init(items: [String: ClosureSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureSegment) {
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

        func list() -> [ClosureSegment] {
            var out: [ClosureSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureSegmentStore() -> any ClosureSegmentStore {
        return MemoryClosureSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureSegmentStore: ClosureSegmentStore {
        var inner: MemoryClosureSegmentStore
        var cache: TTLCache<ClosureSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureSegmentStore, cache: TTLCache<ClosureSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureSegment? {
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

        func save(_ item: ClosureSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureSegment] {
            return inner.list()
        }
    }

    static func newCachedClosureSegmentStore(_ inner: MemoryClosureSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureSegmentStore {
        return CachedClosureSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure segments. Empty fields match all.
    final class ClosureSegmentQuery {
        var facility: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureSegment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureSegment]) -> [ClosureSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureSegments(_ store: any ClosureSegmentStore, query: ClosureSegmentQuery) -> [ClosureSegment] {
        return query.apply(store.list())
    }
}
