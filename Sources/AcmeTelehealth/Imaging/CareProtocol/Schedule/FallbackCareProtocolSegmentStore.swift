import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback care protocol segments by code.
    protocol FallbackCareProtocolSegmentStore {
        func find(_ code: String) -> FallbackCareProtocolSegment?
        func save(_ item: FallbackCareProtocolSegment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareProtocolSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareProtocolSegmentStore: FallbackCareProtocolSegmentStore {
        var items: [String: FallbackCareProtocolSegment]
        var order: [String]

        init(items: [String: FallbackCareProtocolSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareProtocolSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareProtocolSegment) {
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

        func list() -> [FallbackCareProtocolSegment] {
            var out: [FallbackCareProtocolSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareProtocolSegmentStore() -> any FallbackCareProtocolSegmentStore {
        return MemoryFallbackCareProtocolSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareProtocolSegmentStore: FallbackCareProtocolSegmentStore {
        var inner: MemoryFallbackCareProtocolSegmentStore
        var cache: TTLCache<FallbackCareProtocolSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareProtocolSegmentStore, cache: TTLCache<FallbackCareProtocolSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareProtocolSegment? {
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

        func save(_ item: FallbackCareProtocolSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareProtocolSegment] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareProtocolSegmentStore(_ inner: MemoryFallbackCareProtocolSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareProtocolSegmentStore {
        return CachedFallbackCareProtocolSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care protocol segments. Empty fields match all.
    final class FallbackCareProtocolSegmentQuery {
        var country: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareProtocolSegment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCareProtocolSegment]) -> [FallbackCareProtocolSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareProtocolSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareProtocolSegments(_ store: any FallbackCareProtocolSegmentStore, query: FallbackCareProtocolSegmentQuery) -> [FallbackCareProtocolSegment] {
        return query.apply(store.list())
    }
}
