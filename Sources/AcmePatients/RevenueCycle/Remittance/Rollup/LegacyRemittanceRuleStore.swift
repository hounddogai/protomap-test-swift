import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy remittance rules by code.
    protocol LegacyRemittanceRuleStore {
        func find(_ code: String) -> LegacyRemittanceRule?
        func save(_ item: LegacyRemittanceRule)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyRemittanceRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyRemittanceRuleStore: LegacyRemittanceRuleStore {
        var items: [String: LegacyRemittanceRule]
        var order: [String]

        init(items: [String: LegacyRemittanceRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyRemittanceRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyRemittanceRule) {
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

        func list() -> [LegacyRemittanceRule] {
            var out: [LegacyRemittanceRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyRemittanceRuleStore() -> any LegacyRemittanceRuleStore {
        return MemoryLegacyRemittanceRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyRemittanceRuleStore: LegacyRemittanceRuleStore {
        var inner: MemoryLegacyRemittanceRuleStore
        var cache: TTLCache<LegacyRemittanceRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyRemittanceRuleStore, cache: TTLCache<LegacyRemittanceRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyRemittanceRule? {
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

        func save(_ item: LegacyRemittanceRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyRemittanceRule] {
            return inner.list()
        }
    }

    static func newCachedLegacyRemittanceRuleStore(_ inner: MemoryLegacyRemittanceRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyRemittanceRuleStore {
        return CachedLegacyRemittanceRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy remittance rules. Empty fields match all.
    final class LegacyRemittanceRuleQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyRemittanceRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyRemittanceRule]) -> [LegacyRemittanceRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyRemittanceRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyRemittanceRules(_ store: any LegacyRemittanceRuleStore, query: LegacyRemittanceRuleQuery) -> [LegacyRemittanceRule] {
        return query.apply(store.list())
    }
}
