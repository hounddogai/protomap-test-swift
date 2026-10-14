import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered care protocol segments by code.
    protocol TieredCareProtocolSegmentStore {
        func find(_ code: String) -> TieredCareProtocolSegment?
        func save(_ item: TieredCareProtocolSegment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareProtocolSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareProtocolSegmentStore: TieredCareProtocolSegmentStore {
        var items: [String: TieredCareProtocolSegment]
        var order: [String]

        init(items: [String: TieredCareProtocolSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareProtocolSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareProtocolSegment) {
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

        func list() -> [TieredCareProtocolSegment] {
            var out: [TieredCareProtocolSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareProtocolSegmentStore() -> any TieredCareProtocolSegmentStore {
        return MemoryTieredCareProtocolSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareProtocolSegmentStore: TieredCareProtocolSegmentStore {
        var inner: MemoryTieredCareProtocolSegmentStore
        var cache: TTLCache<TieredCareProtocolSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareProtocolSegmentStore, cache: TTLCache<TieredCareProtocolSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareProtocolSegment? {
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

        func save(_ item: TieredCareProtocolSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareProtocolSegment] {
            return inner.list()
        }
    }

    static func newCachedTieredCareProtocolSegmentStore(_ inner: MemoryTieredCareProtocolSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareProtocolSegmentStore {
        return CachedTieredCareProtocolSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care protocol segments. Empty fields match all.
    final class TieredCareProtocolSegmentQuery {
        var unit: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minWeight: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareProtocolSegment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCareProtocolSegment]) -> [TieredCareProtocolSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareProtocolSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareProtocolSegments(_ store: any TieredCareProtocolSegmentStore, query: TieredCareProtocolSegmentQuery) -> [TieredCareProtocolSegment] {
        return query.apply(store.list())
    }
}
