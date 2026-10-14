import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted remittance groups by code.
    protocol WeightedRemittanceGroupStore {
        func find(_ code: String) -> WeightedRemittanceGroup?
        func save(_ item: WeightedRemittanceGroup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedRemittanceGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedRemittanceGroupStore: WeightedRemittanceGroupStore {
        var items: [String: WeightedRemittanceGroup]
        var order: [String]

        init(items: [String: WeightedRemittanceGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedRemittanceGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedRemittanceGroup) {
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

        func list() -> [WeightedRemittanceGroup] {
            var out: [WeightedRemittanceGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedRemittanceGroupStore() -> any WeightedRemittanceGroupStore {
        return MemoryWeightedRemittanceGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedRemittanceGroupStore: WeightedRemittanceGroupStore {
        var inner: MemoryWeightedRemittanceGroupStore
        var cache: TTLCache<WeightedRemittanceGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedRemittanceGroupStore, cache: TTLCache<WeightedRemittanceGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedRemittanceGroup? {
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

        func save(_ item: WeightedRemittanceGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedRemittanceGroup] {
            return inner.list()
        }
    }

    static func newCachedWeightedRemittanceGroupStore(_ inner: MemoryWeightedRemittanceGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedRemittanceGroupStore {
        return CachedWeightedRemittanceGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted remittance groups. Empty fields match all.
    final class WeightedRemittanceGroupQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedRemittanceGroup) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [WeightedRemittanceGroup]) -> [WeightedRemittanceGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedRemittanceGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedRemittanceGroups(_ store: any WeightedRemittanceGroupStore, query: WeightedRemittanceGroupQuery) -> [WeightedRemittanceGroup] {
        return query.apply(store.list())
    }
}
