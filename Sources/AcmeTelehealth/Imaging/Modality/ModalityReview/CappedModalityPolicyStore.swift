import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped modality policies by code.
    protocol CappedModalityPolicyStore {
        func find(_ code: String) -> CappedModalityPolicy?
        func save(_ item: CappedModalityPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [CappedModalityPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedModalityPolicyStore: CappedModalityPolicyStore {
        var items: [String: CappedModalityPolicy]
        var order: [String]

        init(items: [String: CappedModalityPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedModalityPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedModalityPolicy) {
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

        func list() -> [CappedModalityPolicy] {
            var out: [CappedModalityPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedModalityPolicyStore() -> any CappedModalityPolicyStore {
        return MemoryCappedModalityPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedModalityPolicyStore: CappedModalityPolicyStore {
        var inner: MemoryCappedModalityPolicyStore
        var cache: TTLCache<CappedModalityPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedModalityPolicyStore, cache: TTLCache<CappedModalityPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedModalityPolicy? {
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

        func save(_ item: CappedModalityPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedModalityPolicy] {
            return inner.list()
        }
    }

    static func newCachedCappedModalityPolicyStore(_ inner: MemoryCappedModalityPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedModalityPolicyStore {
        return CachedCappedModalityPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped modality policies. Empty fields match all.
    final class CappedModalityPolicyQuery {
        var ward: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCost: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedModalityPolicy) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedModalityPolicy]) -> [CappedModalityPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedModalityPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedModalityPolicies(_ store: any CappedModalityPolicyStore, query: CappedModalityPolicyQuery) -> [CappedModalityPolicy] {
        return query.apply(store.list())
    }
}
