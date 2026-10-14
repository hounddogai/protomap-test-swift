import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback courier segments by code.
    protocol FallbackCourierSegmentStore {
        func find(_ code: String) -> FallbackCourierSegment?
        func save(_ item: FallbackCourierSegment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCourierSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCourierSegmentStore: FallbackCourierSegmentStore {
        var items: [String: FallbackCourierSegment]
        var order: [String]

        init(items: [String: FallbackCourierSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCourierSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCourierSegment) {
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

        func list() -> [FallbackCourierSegment] {
            var out: [FallbackCourierSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCourierSegmentStore() -> any FallbackCourierSegmentStore {
        return MemoryFallbackCourierSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCourierSegmentStore: FallbackCourierSegmentStore {
        var inner: MemoryFallbackCourierSegmentStore
        var cache: TTLCache<FallbackCourierSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCourierSegmentStore, cache: TTLCache<FallbackCourierSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCourierSegment? {
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

        func save(_ item: FallbackCourierSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCourierSegment] {
            return inner.list()
        }
    }

    static func newCachedFallbackCourierSegmentStore(_ inner: MemoryFallbackCourierSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCourierSegmentStore {
        return CachedFallbackCourierSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback courier segments. Empty fields match all.
    final class FallbackCourierSegmentQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCourierSegment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCourierSegment]) -> [FallbackCourierSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCourierSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCourierSegments(_ store: any FallbackCourierSegmentStore, query: FallbackCourierSegmentQuery) -> [FallbackCourierSegment] {
        return query.apply(store.list())
    }
}
