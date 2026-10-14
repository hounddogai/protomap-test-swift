import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global disclosure rules by code.
    protocol GlobalDisclosureRuleStore {
        func find(_ code: String) -> GlobalDisclosureRule?
        func save(_ item: GlobalDisclosureRule)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDisclosureRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDisclosureRuleStore: GlobalDisclosureRuleStore {
        var items: [String: GlobalDisclosureRule]
        var order: [String]

        init(items: [String: GlobalDisclosureRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDisclosureRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDisclosureRule) {
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

        func list() -> [GlobalDisclosureRule] {
            var out: [GlobalDisclosureRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDisclosureRuleStore() -> any GlobalDisclosureRuleStore {
        return MemoryGlobalDisclosureRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDisclosureRuleStore: GlobalDisclosureRuleStore {
        var inner: MemoryGlobalDisclosureRuleStore
        var cache: TTLCache<GlobalDisclosureRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDisclosureRuleStore, cache: TTLCache<GlobalDisclosureRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDisclosureRule? {
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

        func save(_ item: GlobalDisclosureRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDisclosureRule] {
            return inner.list()
        }
    }

    static func newCachedGlobalDisclosureRuleStore(_ inner: MemoryGlobalDisclosureRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDisclosureRuleStore {
        return CachedGlobalDisclosureRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global disclosure rules. Empty fields match all.
    final class GlobalDisclosureRuleQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDisclosureRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalDisclosureRule]) -> [GlobalDisclosureRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDisclosureRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDisclosureRules(_ store: any GlobalDisclosureRuleStore, query: GlobalDisclosureRuleQuery) -> [GlobalDisclosureRule] {
        return query.apply(store.list())
    }
}
