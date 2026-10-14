import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict charge groups by code.
    protocol StrictChargeGroupStore {
        func find(_ code: String) -> StrictChargeGroup?
        func save(_ item: StrictChargeGroup)
        func remove(_ code: String) -> Bool
        func list() -> [StrictChargeGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictChargeGroupStore: StrictChargeGroupStore {
        var items: [String: StrictChargeGroup]
        var order: [String]

        init(items: [String: StrictChargeGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictChargeGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictChargeGroup) {
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

        func list() -> [StrictChargeGroup] {
            var out: [StrictChargeGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictChargeGroupStore() -> any StrictChargeGroupStore {
        return MemoryStrictChargeGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictChargeGroupStore: StrictChargeGroupStore {
        var inner: MemoryStrictChargeGroupStore
        var cache: TTLCache<StrictChargeGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictChargeGroupStore, cache: TTLCache<StrictChargeGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictChargeGroup? {
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

        func save(_ item: StrictChargeGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictChargeGroup] {
            return inner.list()
        }
    }

    static func newCachedStrictChargeGroupStore(_ inner: MemoryStrictChargeGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictChargeGroupStore {
        return CachedStrictChargeGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict charge groups. Empty fields match all.
    final class StrictChargeGroupQuery {
        var unit: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minAmount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictChargeGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictChargeGroup]) -> [StrictChargeGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictChargeGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictChargeGroups(_ store: any StrictChargeGroupStore, query: StrictChargeGroupQuery) -> [StrictChargeGroup] {
        return query.apply(store.list())
    }
}
