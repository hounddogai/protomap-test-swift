import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen rules by code.
    protocol SpecimenRuleStore {
        func find(_ code: String) -> SpecimenRule?
        func save(_ item: SpecimenRule)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenRuleStore: SpecimenRuleStore {
        var items: [String: SpecimenRule]
        var order: [String]

        init(items: [String: SpecimenRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenRule) {
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

        func list() -> [SpecimenRule] {
            var out: [SpecimenRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenRuleStore() -> any SpecimenRuleStore {
        return MemorySpecimenRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenRuleStore: SpecimenRuleStore {
        var inner: MemorySpecimenRuleStore
        var cache: TTLCache<SpecimenRule>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenRuleStore, cache: TTLCache<SpecimenRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenRule? {
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

        func save(_ item: SpecimenRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenRule] {
            return inner.list()
        }
    }

    static func newCachedSpecimenRuleStore(_ inner: MemorySpecimenRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenRuleStore {
        return CachedSpecimenRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen rules. Empty fields match all.
    final class SpecimenRuleQuery {
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

        func matches(_ item: SpecimenRule) -> Bool {
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

        func apply(_ items: [SpecimenRule]) -> [SpecimenRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenRules(_ store: any SpecimenRuleStore, query: SpecimenRuleQuery) -> [SpecimenRule] {
        return query.apply(store.list())
    }
}
