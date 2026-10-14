import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global worklist rules by code.
    protocol GlobalWorklistRuleStore {
        func find(_ code: String) -> GlobalWorklistRule?
        func save(_ item: GlobalWorklistRule)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalWorklistRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalWorklistRuleStore: GlobalWorklistRuleStore {
        var items: [String: GlobalWorklistRule]
        var order: [String]

        init(items: [String: GlobalWorklistRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalWorklistRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalWorklistRule) {
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

        func list() -> [GlobalWorklistRule] {
            var out: [GlobalWorklistRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalWorklistRuleStore() -> any GlobalWorklistRuleStore {
        return MemoryGlobalWorklistRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalWorklistRuleStore: GlobalWorklistRuleStore {
        var inner: MemoryGlobalWorklistRuleStore
        var cache: TTLCache<GlobalWorklistRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalWorklistRuleStore, cache: TTLCache<GlobalWorklistRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalWorklistRule? {
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

        func save(_ item: GlobalWorklistRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalWorklistRule] {
            return inner.list()
        }
    }

    static func newCachedGlobalWorklistRuleStore(_ inner: MemoryGlobalWorklistRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalWorklistRuleStore {
        return CachedGlobalWorklistRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global worklist rules. Empty fields match all.
    final class GlobalWorklistRuleQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalWorklistRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalWorklistRule]) -> [GlobalWorklistRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalWorklistRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalWorklistRules(_ store: any GlobalWorklistRuleStore, query: GlobalWorklistRuleQuery) -> [GlobalWorklistRule] {
        return query.apply(store.list())
    }
}
