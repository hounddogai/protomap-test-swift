import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range rules by code.
    protocol ReferenceRangeRuleStore {
        func find(_ code: String) -> ReferenceRangeRule?
        func save(_ item: ReferenceRangeRule)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeRuleStore: ReferenceRangeRuleStore {
        var items: [String: ReferenceRangeRule]
        var order: [String]

        init(items: [String: ReferenceRangeRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeRule) {
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

        func list() -> [ReferenceRangeRule] {
            var out: [ReferenceRangeRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeRuleStore() -> any ReferenceRangeRuleStore {
        return MemoryReferenceRangeRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeRuleStore: ReferenceRangeRuleStore {
        var inner: MemoryReferenceRangeRuleStore
        var cache: TTLCache<ReferenceRangeRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeRuleStore, cache: TTLCache<ReferenceRangeRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeRule? {
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

        func save(_ item: ReferenceRangeRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeRule] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeRuleStore(_ inner: MemoryReferenceRangeRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeRuleStore {
        return CachedReferenceRangeRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range rules. Empty fields match all.
    final class ReferenceRangeRuleQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeRule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeRule]) -> [ReferenceRangeRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeRules(_ store: any ReferenceRangeRuleStore, query: ReferenceRangeRuleQuery) -> [ReferenceRangeRule] {
        return query.apply(store.list())
    }
}
