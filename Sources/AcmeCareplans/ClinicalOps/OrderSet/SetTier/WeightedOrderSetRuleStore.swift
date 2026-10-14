import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted order set rules by code.
    protocol WeightedOrderSetRuleStore {
        func find(_ code: String) -> WeightedOrderSetRule?
        func save(_ item: WeightedOrderSetRule)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedOrderSetRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedOrderSetRuleStore: WeightedOrderSetRuleStore {
        var items: [String: WeightedOrderSetRule]
        var order: [String]

        init(items: [String: WeightedOrderSetRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedOrderSetRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedOrderSetRule) {
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

        func list() -> [WeightedOrderSetRule] {
            var out: [WeightedOrderSetRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedOrderSetRuleStore() -> any WeightedOrderSetRuleStore {
        return MemoryWeightedOrderSetRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedOrderSetRuleStore: WeightedOrderSetRuleStore {
        var inner: MemoryWeightedOrderSetRuleStore
        var cache: TTLCache<WeightedOrderSetRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedOrderSetRuleStore, cache: TTLCache<WeightedOrderSetRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedOrderSetRule? {
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

        func save(_ item: WeightedOrderSetRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedOrderSetRule] {
            return inner.list()
        }
    }

    static func newCachedWeightedOrderSetRuleStore(_ inner: MemoryWeightedOrderSetRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedOrderSetRuleStore {
        return CachedWeightedOrderSetRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted order set rules. Empty fields match all.
    final class WeightedOrderSetRuleQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedOrderSetRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedOrderSetRule]) -> [WeightedOrderSetRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedOrderSetRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedOrderSetRules(_ store: any WeightedOrderSetRuleStore, query: WeightedOrderSetRuleQuery) -> [WeightedOrderSetRule] {
        return query.apply(store.list())
    }
}
