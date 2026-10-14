import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal statement rules by code.
    protocol SeasonalStatementRuleStore {
        func find(_ code: String) -> SeasonalStatementRule?
        func save(_ item: SeasonalStatementRule)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalStatementRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalStatementRuleStore: SeasonalStatementRuleStore {
        var items: [String: SeasonalStatementRule]
        var order: [String]

        init(items: [String: SeasonalStatementRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalStatementRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalStatementRule) {
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

        func list() -> [SeasonalStatementRule] {
            var out: [SeasonalStatementRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalStatementRuleStore() -> any SeasonalStatementRuleStore {
        return MemorySeasonalStatementRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalStatementRuleStore: SeasonalStatementRuleStore {
        var inner: MemorySeasonalStatementRuleStore
        var cache: TTLCache<SeasonalStatementRule>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalStatementRuleStore, cache: TTLCache<SeasonalStatementRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalStatementRule? {
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

        func save(_ item: SeasonalStatementRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalStatementRule] {
            return inner.list()
        }
    }

    static func newCachedSeasonalStatementRuleStore(_ inner: MemorySeasonalStatementRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalStatementRuleStore {
        return CachedSeasonalStatementRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal statement rules. Empty fields match all.
    final class SeasonalStatementRuleQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalStatementRule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalStatementRule]) -> [SeasonalStatementRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalStatementRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalStatementRules(_ store: any SeasonalStatementRuleStore, query: SeasonalStatementRuleQuery) -> [SeasonalStatementRule] {
        return query.apply(store.list())
    }
}
