import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped closure segments by code.
    protocol CappedClosureSegmentStore {
        func find(_ code: String) -> CappedClosureSegment?
        func save(_ item: CappedClosureSegment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedClosureSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedClosureSegmentStore: CappedClosureSegmentStore {
        var items: [String: CappedClosureSegment]
        var order: [String]

        init(items: [String: CappedClosureSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedClosureSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedClosureSegment) {
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

        func list() -> [CappedClosureSegment] {
            var out: [CappedClosureSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedClosureSegmentStore() -> any CappedClosureSegmentStore {
        return MemoryCappedClosureSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedClosureSegmentStore: CappedClosureSegmentStore {
        var inner: MemoryCappedClosureSegmentStore
        var cache: TTLCache<CappedClosureSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedClosureSegmentStore, cache: TTLCache<CappedClosureSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedClosureSegment? {
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

        func save(_ item: CappedClosureSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedClosureSegment] {
            return inner.list()
        }
    }

    static func newCachedCappedClosureSegmentStore(_ inner: MemoryCappedClosureSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedClosureSegmentStore {
        return CachedCappedClosureSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped closure segments. Empty fields match all.
    final class CappedClosureSegmentQuery {
        var facility: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minVersion: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedClosureSegment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedClosureSegment]) -> [CappedClosureSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedClosureSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedClosureSegments(_ store: any CappedClosureSegmentStore, query: CappedClosureSegmentQuery) -> [CappedClosureSegment] {
        return query.apply(store.list())
    }
}
