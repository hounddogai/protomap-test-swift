import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure rules by code.
    protocol DisclosureRuleStore {
        func find(_ code: String) -> DisclosureRule?
        func save(_ item: DisclosureRule)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureRuleStore: DisclosureRuleStore {
        var items: [String: DisclosureRule]
        var order: [String]

        init(items: [String: DisclosureRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureRule) {
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

        func list() -> [DisclosureRule] {
            var out: [DisclosureRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureRuleStore() -> any DisclosureRuleStore {
        return MemoryDisclosureRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureRuleStore: DisclosureRuleStore {
        var inner: MemoryDisclosureRuleStore
        var cache: TTLCache<DisclosureRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureRuleStore, cache: TTLCache<DisclosureRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureRule? {
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

        func save(_ item: DisclosureRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureRule] {
            return inner.list()
        }
    }

    static func newCachedDisclosureRuleStore(_ inner: MemoryDisclosureRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureRuleStore {
        return CachedDisclosureRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure rules. Empty fields match all.
    final class DisclosureRuleQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureRule) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureRule]) -> [DisclosureRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureRules(_ store: any DisclosureRuleStore, query: DisclosureRuleQuery) -> [DisclosureRule] {
        return query.apply(store.list())
    }
}
