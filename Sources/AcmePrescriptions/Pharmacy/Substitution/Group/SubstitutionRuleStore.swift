import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution rules by code.
    protocol SubstitutionRuleStore {
        func find(_ code: String) -> SubstitutionRule?
        func save(_ item: SubstitutionRule)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionRuleStore: SubstitutionRuleStore {
        var items: [String: SubstitutionRule]
        var order: [String]

        init(items: [String: SubstitutionRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionRule) {
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

        func list() -> [SubstitutionRule] {
            var out: [SubstitutionRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionRuleStore() -> any SubstitutionRuleStore {
        return MemorySubstitutionRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionRuleStore: SubstitutionRuleStore {
        var inner: MemorySubstitutionRuleStore
        var cache: TTLCache<SubstitutionRule>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionRuleStore, cache: TTLCache<SubstitutionRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionRule? {
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

        func save(_ item: SubstitutionRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionRule] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionRuleStore(_ inner: MemorySubstitutionRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionRuleStore {
        return CachedSubstitutionRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution rules. Empty fields match all.
    final class SubstitutionRuleQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionRule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SubstitutionRule]) -> [SubstitutionRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionRules(_ store: any SubstitutionRuleStore, query: SubstitutionRuleQuery) -> [SubstitutionRule] {
        return query.apply(store.list())
    }
}
