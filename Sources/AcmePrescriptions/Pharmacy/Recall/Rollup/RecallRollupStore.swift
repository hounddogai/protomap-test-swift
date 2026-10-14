import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall rollups by code.
    protocol RecallRollupStore {
        func find(_ code: String) -> RecallRollup?
        func save(_ item: RecallRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RecallRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallRollupStore: RecallRollupStore {
        var items: [String: RecallRollup]
        var order: [String]

        init(items: [String: RecallRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallRollup) {
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

        func list() -> [RecallRollup] {
            var out: [RecallRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallRollupStore() -> any RecallRollupStore {
        return MemoryRecallRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallRollupStore: RecallRollupStore {
        var inner: MemoryRecallRollupStore
        var cache: TTLCache<RecallRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallRollupStore, cache: TTLCache<RecallRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallRollup? {
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

        func save(_ item: RecallRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallRollup] {
            return inner.list()
        }
    }

    static func newCachedRecallRollupStore(_ inner: MemoryRecallRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallRollupStore {
        return CachedRecallRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall rollups. Empty fields match all.
    final class RecallRollupQuery {
        var region: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCost: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallRollup]) -> [RecallRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallRollups(_ store: any RecallRollupStore, query: RecallRollupQuery) -> [RecallRollup] {
        return query.apply(store.list())
    }
}
