import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal closure rules by code.
    protocol SeasonalClosureRuleStore {
        func find(_ code: String) -> SeasonalClosureRule?
        func save(_ item: SeasonalClosureRule)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalClosureRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalClosureRuleStore: SeasonalClosureRuleStore {
        var items: [String: SeasonalClosureRule]
        var order: [String]

        init(items: [String: SeasonalClosureRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalClosureRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalClosureRule) {
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

        func list() -> [SeasonalClosureRule] {
            var out: [SeasonalClosureRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalClosureRuleStore() -> any SeasonalClosureRuleStore {
        return MemorySeasonalClosureRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalClosureRuleStore: SeasonalClosureRuleStore {
        var inner: MemorySeasonalClosureRuleStore
        var cache: TTLCache<SeasonalClosureRule>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalClosureRuleStore, cache: TTLCache<SeasonalClosureRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalClosureRule? {
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

        func save(_ item: SeasonalClosureRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalClosureRule] {
            return inner.list()
        }
    }

    static func newCachedSeasonalClosureRuleStore(_ inner: MemorySeasonalClosureRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalClosureRuleStore {
        return CachedSeasonalClosureRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal closure rules. Empty fields match all.
    final class SeasonalClosureRuleQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalClosureRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalClosureRule]) -> [SeasonalClosureRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalClosureRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalClosureRules(_ store: any SeasonalClosureRuleStore, query: SeasonalClosureRuleQuery) -> [SeasonalClosureRule] {
        return query.apply(store.list())
    }
}
