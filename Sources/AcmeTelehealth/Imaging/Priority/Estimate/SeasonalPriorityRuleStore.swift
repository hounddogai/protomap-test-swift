import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal priority rules by code.
    protocol SeasonalPriorityRuleStore {
        func find(_ code: String) -> SeasonalPriorityRule?
        func save(_ item: SeasonalPriorityRule)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalPriorityRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalPriorityRuleStore: SeasonalPriorityRuleStore {
        var items: [String: SeasonalPriorityRule]
        var order: [String]

        init(items: [String: SeasonalPriorityRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalPriorityRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalPriorityRule) {
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

        func list() -> [SeasonalPriorityRule] {
            var out: [SeasonalPriorityRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalPriorityRuleStore() -> any SeasonalPriorityRuleStore {
        return MemorySeasonalPriorityRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalPriorityRuleStore: SeasonalPriorityRuleStore {
        var inner: MemorySeasonalPriorityRuleStore
        var cache: TTLCache<SeasonalPriorityRule>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalPriorityRuleStore, cache: TTLCache<SeasonalPriorityRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalPriorityRule? {
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

        func save(_ item: SeasonalPriorityRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalPriorityRule] {
            return inner.list()
        }
    }

    static func newCachedSeasonalPriorityRuleStore(_ inner: MemorySeasonalPriorityRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalPriorityRuleStore {
        return CachedSeasonalPriorityRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal priority rules. Empty fields match all.
    final class SeasonalPriorityRuleQuery {
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

        func matches(_ item: SeasonalPriorityRule) -> Bool {
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

        func apply(_ items: [SeasonalPriorityRule]) -> [SeasonalPriorityRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalPriorityRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalPriorityRules(_ store: any SeasonalPriorityRuleStore, query: SeasonalPriorityRuleQuery) -> [SeasonalPriorityRule] {
        return query.apply(store.list())
    }
}
