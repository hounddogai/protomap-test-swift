import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge rollups by code.
    protocol ChargeRollupStore {
        func find(_ code: String) -> ChargeRollup?
        func save(_ item: ChargeRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeRollupStore: ChargeRollupStore {
        var items: [String: ChargeRollup]
        var order: [String]

        init(items: [String: ChargeRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeRollup) {
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

        func list() -> [ChargeRollup] {
            var out: [ChargeRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeRollupStore() -> any ChargeRollupStore {
        return MemoryChargeRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeRollupStore: ChargeRollupStore {
        var inner: MemoryChargeRollupStore
        var cache: TTLCache<ChargeRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeRollupStore, cache: TTLCache<ChargeRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeRollup? {
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

        func save(_ item: ChargeRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeRollup] {
            return inner.list()
        }
    }

    static func newCachedChargeRollupStore(_ inner: MemoryChargeRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeRollupStore {
        return CachedChargeRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge rollups. Empty fields match all.
    final class ChargeRollupQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeRollup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeRollup]) -> [ChargeRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeRollups(_ store: any ChargeRollupStore, query: ChargeRollupQuery) -> [ChargeRollup] {
        return query.apply(store.list())
    }
}
