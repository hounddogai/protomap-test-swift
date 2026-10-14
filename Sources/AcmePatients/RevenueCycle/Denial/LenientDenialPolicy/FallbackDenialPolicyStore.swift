import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback denial policies by code.
    protocol FallbackDenialPolicyStore {
        func find(_ code: String) -> FallbackDenialPolicy?
        func save(_ item: FallbackDenialPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDenialPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDenialPolicyStore: FallbackDenialPolicyStore {
        var items: [String: FallbackDenialPolicy]
        var order: [String]

        init(items: [String: FallbackDenialPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDenialPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDenialPolicy) {
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

        func list() -> [FallbackDenialPolicy] {
            var out: [FallbackDenialPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDenialPolicyStore() -> any FallbackDenialPolicyStore {
        return MemoryFallbackDenialPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDenialPolicyStore: FallbackDenialPolicyStore {
        var inner: MemoryFallbackDenialPolicyStore
        var cache: TTLCache<FallbackDenialPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDenialPolicyStore, cache: TTLCache<FallbackDenialPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDenialPolicy? {
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

        func save(_ item: FallbackDenialPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDenialPolicy] {
            return inner.list()
        }
    }

    static func newCachedFallbackDenialPolicyStore(_ inner: MemoryFallbackDenialPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDenialPolicyStore {
        return CachedFallbackDenialPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback denial policies. Empty fields match all.
    final class FallbackDenialPolicyQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDenialPolicy) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [FallbackDenialPolicy]) -> [FallbackDenialPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDenialPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDenialPolicies(_ store: any FallbackDenialPolicyStore, query: FallbackDenialPolicyQuery) -> [FallbackDenialPolicy] {
        return query.apply(store.list())
    }
}
