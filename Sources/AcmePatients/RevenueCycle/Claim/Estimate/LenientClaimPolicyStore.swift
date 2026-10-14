import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient claim policies by code.
    protocol LenientClaimPolicyStore {
        func find(_ code: String) -> LenientClaimPolicy?
        func save(_ item: LenientClaimPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClaimPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClaimPolicyStore: LenientClaimPolicyStore {
        var items: [String: LenientClaimPolicy]
        var order: [String]

        init(items: [String: LenientClaimPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClaimPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClaimPolicy) {
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

        func list() -> [LenientClaimPolicy] {
            var out: [LenientClaimPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClaimPolicyStore() -> any LenientClaimPolicyStore {
        return MemoryLenientClaimPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClaimPolicyStore: LenientClaimPolicyStore {
        var inner: MemoryLenientClaimPolicyStore
        var cache: TTLCache<LenientClaimPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClaimPolicyStore, cache: TTLCache<LenientClaimPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClaimPolicy? {
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

        func save(_ item: LenientClaimPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClaimPolicy] {
            return inner.list()
        }
    }

    static func newCachedLenientClaimPolicyStore(_ inner: MemoryLenientClaimPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClaimPolicyStore {
        return CachedLenientClaimPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient claim policies. Empty fields match all.
    final class LenientClaimPolicyQuery {
        var region: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minScore: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClaimPolicy) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [LenientClaimPolicy]) -> [LenientClaimPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClaimPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClaimPolicies(_ store: any LenientClaimPolicyStore, query: LenientClaimPolicyQuery) -> [LenientClaimPolicy] {
        return query.apply(store.list())
    }
}
