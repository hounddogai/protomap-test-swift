import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted follow up rules by code.
    protocol WeightedFollowUpRuleStore {
        func find(_ code: String) -> WeightedFollowUpRule?
        func save(_ item: WeightedFollowUpRule)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedFollowUpRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedFollowUpRuleStore: WeightedFollowUpRuleStore {
        var items: [String: WeightedFollowUpRule]
        var order: [String]

        init(items: [String: WeightedFollowUpRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedFollowUpRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedFollowUpRule) {
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

        func list() -> [WeightedFollowUpRule] {
            var out: [WeightedFollowUpRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedFollowUpRuleStore() -> any WeightedFollowUpRuleStore {
        return MemoryWeightedFollowUpRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedFollowUpRuleStore: WeightedFollowUpRuleStore {
        var inner: MemoryWeightedFollowUpRuleStore
        var cache: TTLCache<WeightedFollowUpRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedFollowUpRuleStore, cache: TTLCache<WeightedFollowUpRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedFollowUpRule? {
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

        func save(_ item: WeightedFollowUpRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedFollowUpRule] {
            return inner.list()
        }
    }

    static func newCachedWeightedFollowUpRuleStore(_ inner: MemoryWeightedFollowUpRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedFollowUpRuleStore {
        return CachedWeightedFollowUpRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted follow up rules. Empty fields match all.
    final class WeightedFollowUpRuleQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedFollowUpRule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [WeightedFollowUpRule]) -> [WeightedFollowUpRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedFollowUpRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedFollowUpRules(_ store: any WeightedFollowUpRuleStore, query: WeightedFollowUpRuleQuery) -> [WeightedFollowUpRule] {
        return query.apply(store.list())
    }
}
