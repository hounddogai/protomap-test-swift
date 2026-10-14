import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language rules by code.
    protocol LanguageRuleStore {
        func find(_ code: String) -> LanguageRule?
        func save(_ item: LanguageRule)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageRuleStore: LanguageRuleStore {
        var items: [String: LanguageRule]
        var order: [String]

        init(items: [String: LanguageRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageRule) {
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

        func list() -> [LanguageRule] {
            var out: [LanguageRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageRuleStore() -> any LanguageRuleStore {
        return MemoryLanguageRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageRuleStore: LanguageRuleStore {
        var inner: MemoryLanguageRuleStore
        var cache: TTLCache<LanguageRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageRuleStore, cache: TTLCache<LanguageRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageRule? {
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

        func save(_ item: LanguageRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageRule] {
            return inner.list()
        }
    }

    static func newCachedLanguageRuleStore(_ inner: MemoryLanguageRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageRuleStore {
        return CachedLanguageRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language rules. Empty fields match all.
    final class LanguageRuleQuery {
        var ward: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCost: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageRule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [LanguageRule]) -> [LanguageRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageRules(_ store: any LanguageRuleStore, query: LanguageRuleQuery) -> [LanguageRule] {
        return query.apply(store.list())
    }
}
