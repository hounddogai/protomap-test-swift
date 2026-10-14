import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim policies by code.
    protocol ClaimPolicyStore {
        func find(_ code: String) -> ClaimPolicy?
        func save(_ item: ClaimPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimPolicyStore: ClaimPolicyStore {
        var items: [String: ClaimPolicy]
        var order: [String]

        init(items: [String: ClaimPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimPolicy) {
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

        func list() -> [ClaimPolicy] {
            var out: [ClaimPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimPolicyStore() -> any ClaimPolicyStore {
        return MemoryClaimPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimPolicyStore: ClaimPolicyStore {
        var inner: MemoryClaimPolicyStore
        var cache: TTLCache<ClaimPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimPolicyStore, cache: TTLCache<ClaimPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimPolicy? {
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

        func save(_ item: ClaimPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimPolicy] {
            return inner.list()
        }
    }

    static func newCachedClaimPolicyStore(_ inner: MemoryClaimPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimPolicyStore {
        return CachedClaimPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim policies. Empty fields match all.
    final class ClaimPolicyQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimPolicy) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimPolicy]) -> [ClaimPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimPolicies(_ store: any ClaimPolicyStore, query: ClaimPolicyQuery) -> [ClaimPolicy] {
        return query.apply(store.list())
    }
}
