import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped order set rollups by code.
    protocol CappedOrderSetRollupStore {
        func find(_ code: String) -> CappedOrderSetRollup?
        func save(_ item: CappedOrderSetRollup)
        func remove(_ code: String) -> Bool
        func list() -> [CappedOrderSetRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedOrderSetRollupStore: CappedOrderSetRollupStore {
        var items: [String: CappedOrderSetRollup]
        var order: [String]

        init(items: [String: CappedOrderSetRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedOrderSetRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedOrderSetRollup) {
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

        func list() -> [CappedOrderSetRollup] {
            var out: [CappedOrderSetRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedOrderSetRollupStore() -> any CappedOrderSetRollupStore {
        return MemoryCappedOrderSetRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedOrderSetRollupStore: CappedOrderSetRollupStore {
        var inner: MemoryCappedOrderSetRollupStore
        var cache: TTLCache<CappedOrderSetRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedOrderSetRollupStore, cache: TTLCache<CappedOrderSetRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedOrderSetRollup? {
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

        func save(_ item: CappedOrderSetRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedOrderSetRollup] {
            return inner.list()
        }
    }

    static func newCachedCappedOrderSetRollupStore(_ inner: MemoryCappedOrderSetRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedOrderSetRollupStore {
        return CachedCappedOrderSetRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped order set rollups. Empty fields match all.
    final class CappedOrderSetRollupQuery {
        var facility: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedOrderSetRollup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedOrderSetRollup]) -> [CappedOrderSetRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedOrderSetRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedOrderSetRollups(_ store: any CappedOrderSetRollupStore, query: CappedOrderSetRollupQuery) -> [CappedOrderSetRollup] {
        return query.apply(store.list())
    }
}
