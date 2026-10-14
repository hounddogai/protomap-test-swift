import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional consent form rules by code.
    protocol RegionalConsentFormRuleStore {
        func find(_ code: String) -> RegionalConsentFormRule?
        func save(_ item: RegionalConsentFormRule)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalConsentFormRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalConsentFormRuleStore: RegionalConsentFormRuleStore {
        var items: [String: RegionalConsentFormRule]
        var order: [String]

        init(items: [String: RegionalConsentFormRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalConsentFormRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalConsentFormRule) {
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

        func list() -> [RegionalConsentFormRule] {
            var out: [RegionalConsentFormRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalConsentFormRuleStore() -> any RegionalConsentFormRuleStore {
        return MemoryRegionalConsentFormRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalConsentFormRuleStore: RegionalConsentFormRuleStore {
        var inner: MemoryRegionalConsentFormRuleStore
        var cache: TTLCache<RegionalConsentFormRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalConsentFormRuleStore, cache: TTLCache<RegionalConsentFormRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalConsentFormRule? {
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

        func save(_ item: RegionalConsentFormRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalConsentFormRule] {
            return inner.list()
        }
    }

    static func newCachedRegionalConsentFormRuleStore(_ inner: MemoryRegionalConsentFormRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalConsentFormRuleStore {
        return CachedRegionalConsentFormRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional consent form rules. Empty fields match all.
    final class RegionalConsentFormRuleQuery {
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

        func matches(_ item: RegionalConsentFormRule) -> Bool {
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

        func apply(_ items: [RegionalConsentFormRule]) -> [RegionalConsentFormRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalConsentFormRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalConsentFormRules(_ store: any RegionalConsentFormRuleStore, query: RegionalConsentFormRuleQuery) -> [RegionalConsentFormRule] {
        return query.apply(store.list())
    }
}
