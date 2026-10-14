import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default reference range rules by code.
    protocol DefaultReferenceRangeRuleStore {
        func find(_ code: String) -> DefaultReferenceRangeRule?
        func save(_ item: DefaultReferenceRangeRule)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultReferenceRangeRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultReferenceRangeRuleStore: DefaultReferenceRangeRuleStore {
        var items: [String: DefaultReferenceRangeRule]
        var order: [String]

        init(items: [String: DefaultReferenceRangeRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultReferenceRangeRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultReferenceRangeRule) {
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

        func list() -> [DefaultReferenceRangeRule] {
            var out: [DefaultReferenceRangeRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultReferenceRangeRuleStore() -> any DefaultReferenceRangeRuleStore {
        return MemoryDefaultReferenceRangeRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultReferenceRangeRuleStore: DefaultReferenceRangeRuleStore {
        var inner: MemoryDefaultReferenceRangeRuleStore
        var cache: TTLCache<DefaultReferenceRangeRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultReferenceRangeRuleStore, cache: TTLCache<DefaultReferenceRangeRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultReferenceRangeRule? {
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

        func save(_ item: DefaultReferenceRangeRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultReferenceRangeRule] {
            return inner.list()
        }
    }

    static func newCachedDefaultReferenceRangeRuleStore(_ inner: MemoryDefaultReferenceRangeRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultReferenceRangeRuleStore {
        return CachedDefaultReferenceRangeRuleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default reference range rules. Empty fields match all.
    final class DefaultReferenceRangeRuleQuery {
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

        func matches(_ item: DefaultReferenceRangeRule) -> Bool {
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

        func apply(_ items: [DefaultReferenceRangeRule]) -> [DefaultReferenceRangeRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultReferenceRangeRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultReferenceRangeRules(_ store: any DefaultReferenceRangeRuleStore, query: DefaultReferenceRangeRuleQuery) -> [DefaultReferenceRangeRule] {
        return query.apply(store.list())
    }
}
