import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial policies by code.
    protocol DenialPolicyStore {
        func find(_ code: String) -> DenialPolicy?
        func save(_ item: DenialPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [DenialPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialPolicyStore: DenialPolicyStore {
        var items: [String: DenialPolicy]
        var order: [String]

        init(items: [String: DenialPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialPolicy) {
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

        func list() -> [DenialPolicy] {
            var out: [DenialPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialPolicyStore() -> any DenialPolicyStore {
        return MemoryDenialPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialPolicyStore: DenialPolicyStore {
        var inner: MemoryDenialPolicyStore
        var cache: TTLCache<DenialPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialPolicyStore, cache: TTLCache<DenialPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialPolicy? {
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

        func save(_ item: DenialPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialPolicy] {
            return inner.list()
        }
    }

    static func newCachedDenialPolicyStore(_ inner: MemoryDenialPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialPolicyStore {
        return CachedDenialPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial policies. Empty fields match all.
    final class DenialPolicyQuery {
        var region: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialPolicy) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [DenialPolicy]) -> [DenialPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialPolicies(_ store: any DenialPolicyStore, query: DenialPolicyQuery) -> [DenialPolicy] {
        return query.apply(store.list())
    }
}
