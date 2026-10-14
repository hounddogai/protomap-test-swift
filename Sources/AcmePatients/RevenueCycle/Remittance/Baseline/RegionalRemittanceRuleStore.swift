import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional remittance rules by code.
    protocol RegionalRemittanceRuleStore {
        func find(_ code: String) -> RegionalRemittanceRule?
        func save(_ item: RegionalRemittanceRule)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRemittanceRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRemittanceRuleStore: RegionalRemittanceRuleStore {
        var items: [String: RegionalRemittanceRule]
        var order: [String]

        init(items: [String: RegionalRemittanceRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRemittanceRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRemittanceRule) {
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

        func list() -> [RegionalRemittanceRule] {
            var out: [RegionalRemittanceRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRemittanceRuleStore() -> any RegionalRemittanceRuleStore {
        return MemoryRegionalRemittanceRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRemittanceRuleStore: RegionalRemittanceRuleStore {
        var inner: MemoryRegionalRemittanceRuleStore
        var cache: TTLCache<RegionalRemittanceRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRemittanceRuleStore, cache: TTLCache<RegionalRemittanceRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRemittanceRule? {
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

        func save(_ item: RegionalRemittanceRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRemittanceRule] {
            return inner.list()
        }
    }

    static func newCachedRegionalRemittanceRuleStore(_ inner: MemoryRegionalRemittanceRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRemittanceRuleStore {
        return CachedRegionalRemittanceRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional remittance rules. Empty fields match all.
    final class RegionalRemittanceRuleQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRemittanceRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalRemittanceRule]) -> [RegionalRemittanceRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRemittanceRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRemittanceRules(_ store: any RegionalRemittanceRuleStore, query: RegionalRemittanceRuleQuery) -> [RegionalRemittanceRule] {
        return query.apply(store.list())
    }
}
