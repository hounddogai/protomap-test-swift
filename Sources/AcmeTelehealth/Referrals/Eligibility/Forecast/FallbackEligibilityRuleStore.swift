import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback eligibility rules by code.
    protocol FallbackEligibilityRuleStore {
        func find(_ code: String) -> FallbackEligibilityRule?
        func save(_ item: FallbackEligibilityRule)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackEligibilityRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackEligibilityRuleStore: FallbackEligibilityRuleStore {
        var items: [String: FallbackEligibilityRule]
        var order: [String]

        init(items: [String: FallbackEligibilityRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackEligibilityRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackEligibilityRule) {
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

        func list() -> [FallbackEligibilityRule] {
            var out: [FallbackEligibilityRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackEligibilityRuleStore() -> any FallbackEligibilityRuleStore {
        return MemoryFallbackEligibilityRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackEligibilityRuleStore: FallbackEligibilityRuleStore {
        var inner: MemoryFallbackEligibilityRuleStore
        var cache: TTLCache<FallbackEligibilityRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackEligibilityRuleStore, cache: TTLCache<FallbackEligibilityRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackEligibilityRule? {
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

        func save(_ item: FallbackEligibilityRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackEligibilityRule] {
            return inner.list()
        }
    }

    static func newCachedFallbackEligibilityRuleStore(_ inner: MemoryFallbackEligibilityRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackEligibilityRuleStore {
        return CachedFallbackEligibilityRuleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback eligibility rules. Empty fields match all.
    final class FallbackEligibilityRuleQuery {
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

        func matches(_ item: FallbackEligibilityRule) -> Bool {
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

        func apply(_ items: [FallbackEligibilityRule]) -> [FallbackEligibilityRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackEligibilityRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackEligibilityRules(_ store: any FallbackEligibilityRuleStore, query: FallbackEligibilityRuleQuery) -> [FallbackEligibilityRule] {
        return query.apply(store.list())
    }
}
