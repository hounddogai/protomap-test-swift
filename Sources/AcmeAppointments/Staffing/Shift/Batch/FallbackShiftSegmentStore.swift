import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback shift segments by code.
    protocol FallbackShiftSegmentStore {
        func find(_ code: String) -> FallbackShiftSegment?
        func save(_ item: FallbackShiftSegment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackShiftSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackShiftSegmentStore: FallbackShiftSegmentStore {
        var items: [String: FallbackShiftSegment]
        var order: [String]

        init(items: [String: FallbackShiftSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackShiftSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackShiftSegment) {
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

        func list() -> [FallbackShiftSegment] {
            var out: [FallbackShiftSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackShiftSegmentStore() -> any FallbackShiftSegmentStore {
        return MemoryFallbackShiftSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackShiftSegmentStore: FallbackShiftSegmentStore {
        var inner: MemoryFallbackShiftSegmentStore
        var cache: TTLCache<FallbackShiftSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackShiftSegmentStore, cache: TTLCache<FallbackShiftSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackShiftSegment? {
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

        func save(_ item: FallbackShiftSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackShiftSegment] {
            return inner.list()
        }
    }

    static func newCachedFallbackShiftSegmentStore(_ inner: MemoryFallbackShiftSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackShiftSegmentStore {
        return CachedFallbackShiftSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback shift segments. Empty fields match all.
    final class FallbackShiftSegmentQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackShiftSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackShiftSegment]) -> [FallbackShiftSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackShiftSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackShiftSegments(_ store: any FallbackShiftSegmentStore, query: FallbackShiftSegmentQuery) -> [FallbackShiftSegment] {
        return query.apply(store.list())
    }
}
