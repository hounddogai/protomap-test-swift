import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation policies by code.
    protocol IsolationPolicyStore {
        func find(_ code: String) -> IsolationPolicy?
        func save(_ item: IsolationPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationPolicyStore: IsolationPolicyStore {
        var items: [String: IsolationPolicy]
        var order: [String]

        init(items: [String: IsolationPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationPolicy) {
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

        func list() -> [IsolationPolicy] {
            var out: [IsolationPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationPolicyStore() -> any IsolationPolicyStore {
        return MemoryIsolationPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationPolicyStore: IsolationPolicyStore {
        var inner: MemoryIsolationPolicyStore
        var cache: TTLCache<IsolationPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationPolicyStore, cache: TTLCache<IsolationPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationPolicy? {
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

        func save(_ item: IsolationPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationPolicy] {
            return inner.list()
        }
    }

    static func newCachedIsolationPolicyStore(_ inner: MemoryIsolationPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationPolicyStore {
        return CachedIsolationPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation policies. Empty fields match all.
    final class IsolationPolicyQuery {
        var category: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationPolicy) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationPolicy]) -> [IsolationPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationPolicies(_ store: any IsolationPolicyStore, query: IsolationPolicyQuery) -> [IsolationPolicy] {
        return query.apply(store.list())
    }
}
