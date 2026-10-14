import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional panel rules by code.
    protocol RegionalPanelRuleStore {
        func find(_ code: String) -> RegionalPanelRule?
        func save(_ item: RegionalPanelRule)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalPanelRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalPanelRuleStore: RegionalPanelRuleStore {
        var items: [String: RegionalPanelRule]
        var order: [String]

        init(items: [String: RegionalPanelRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalPanelRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalPanelRule) {
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

        func list() -> [RegionalPanelRule] {
            var out: [RegionalPanelRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalPanelRuleStore() -> any RegionalPanelRuleStore {
        return MemoryRegionalPanelRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalPanelRuleStore: RegionalPanelRuleStore {
        var inner: MemoryRegionalPanelRuleStore
        var cache: TTLCache<RegionalPanelRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalPanelRuleStore, cache: TTLCache<RegionalPanelRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalPanelRule? {
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

        func save(_ item: RegionalPanelRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalPanelRule] {
            return inner.list()
        }
    }

    static func newCachedRegionalPanelRuleStore(_ inner: MemoryRegionalPanelRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalPanelRuleStore {
        return CachedRegionalPanelRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional panel rules. Empty fields match all.
    final class RegionalPanelRuleQuery {
        var facility: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minLimit: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalPanelRule) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalPanelRule]) -> [RegionalPanelRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalPanelRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalPanelRules(_ store: any RegionalPanelRuleStore, query: RegionalPanelRuleQuery) -> [RegionalPanelRule] {
        return query.apply(store.list())
    }
}
