import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending denial policies by code.
    protocol PendingDenialPolicyStore {
        func find(_ code: String) -> PendingDenialPolicy?
        func save(_ item: PendingDenialPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDenialPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDenialPolicyStore: PendingDenialPolicyStore {
        var items: [String: PendingDenialPolicy]
        var order: [String]

        init(items: [String: PendingDenialPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDenialPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDenialPolicy) {
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

        func list() -> [PendingDenialPolicy] {
            var out: [PendingDenialPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDenialPolicyStore() -> any PendingDenialPolicyStore {
        return MemoryPendingDenialPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDenialPolicyStore: PendingDenialPolicyStore {
        var inner: MemoryPendingDenialPolicyStore
        var cache: TTLCache<PendingDenialPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDenialPolicyStore, cache: TTLCache<PendingDenialPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDenialPolicy? {
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

        func save(_ item: PendingDenialPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDenialPolicy] {
            return inner.list()
        }
    }

    static func newCachedPendingDenialPolicyStore(_ inner: MemoryPendingDenialPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDenialPolicyStore {
        return CachedPendingDenialPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending denial policies. Empty fields match all.
    final class PendingDenialPolicyQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDenialPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingDenialPolicy]) -> [PendingDenialPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDenialPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDenialPolicies(_ store: any PendingDenialPolicyStore, query: PendingDenialPolicyQuery) -> [PendingDenialPolicy] {
        return query.apply(store.list())
    }
}
