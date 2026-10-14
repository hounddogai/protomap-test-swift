import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted formulary groups by code.
    protocol WeightedFormularyGroupStore {
        func find(_ code: String) -> WeightedFormularyGroup?
        func save(_ item: WeightedFormularyGroup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedFormularyGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedFormularyGroupStore: WeightedFormularyGroupStore {
        var items: [String: WeightedFormularyGroup]
        var order: [String]

        init(items: [String: WeightedFormularyGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedFormularyGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedFormularyGroup) {
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

        func list() -> [WeightedFormularyGroup] {
            var out: [WeightedFormularyGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedFormularyGroupStore() -> any WeightedFormularyGroupStore {
        return MemoryWeightedFormularyGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedFormularyGroupStore: WeightedFormularyGroupStore {
        var inner: MemoryWeightedFormularyGroupStore
        var cache: TTLCache<WeightedFormularyGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedFormularyGroupStore, cache: TTLCache<WeightedFormularyGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedFormularyGroup? {
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

        func save(_ item: WeightedFormularyGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedFormularyGroup] {
            return inner.list()
        }
    }

    static func newCachedWeightedFormularyGroupStore(_ inner: MemoryWeightedFormularyGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedFormularyGroupStore {
        return CachedWeightedFormularyGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted formulary groups. Empty fields match all.
    final class WeightedFormularyGroupQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedFormularyGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedFormularyGroup]) -> [WeightedFormularyGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedFormularyGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedFormularyGroups(_ store: any WeightedFormularyGroupStore, query: WeightedFormularyGroupQuery) -> [WeightedFormularyGroup] {
        return query.apply(store.list())
    }
}
