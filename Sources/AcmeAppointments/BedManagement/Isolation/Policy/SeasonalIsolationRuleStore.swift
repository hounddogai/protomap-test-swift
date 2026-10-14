import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps seasonal isolation rules by code.
    protocol SeasonalIsolationRuleStore {
        func find(_ code: String) -> SeasonalIsolationRule?
        func save(_ item: SeasonalIsolationRule)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalIsolationRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalIsolationRuleStore: SeasonalIsolationRuleStore {
        var items: [String: SeasonalIsolationRule]
        var order: [String]

        init(items: [String: SeasonalIsolationRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalIsolationRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalIsolationRule) {
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

        func list() -> [SeasonalIsolationRule] {
            var out: [SeasonalIsolationRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalIsolationRuleStore() -> any SeasonalIsolationRuleStore {
        return MemorySeasonalIsolationRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalIsolationRuleStore: SeasonalIsolationRuleStore {
        var inner: MemorySeasonalIsolationRuleStore
        var cache: TTLCache<SeasonalIsolationRule>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalIsolationRuleStore, cache: TTLCache<SeasonalIsolationRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalIsolationRule? {
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

        func save(_ item: SeasonalIsolationRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalIsolationRule] {
            return inner.list()
        }
    }

    static func newCachedSeasonalIsolationRuleStore(_ inner: MemorySeasonalIsolationRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalIsolationRuleStore {
        return CachedSeasonalIsolationRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal isolation rules. Empty fields match all.
    final class SeasonalIsolationRuleQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalIsolationRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalIsolationRule]) -> [SeasonalIsolationRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalIsolationRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalIsolationRules(_ store: any SeasonalIsolationRuleStore, query: SeasonalIsolationRuleQuery) -> [SeasonalIsolationRule] {
        return query.apply(store.list())
    }
}
