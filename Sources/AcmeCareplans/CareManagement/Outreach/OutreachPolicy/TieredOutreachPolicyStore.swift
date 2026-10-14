import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered outreach policies by code.
    protocol TieredOutreachPolicyStore {
        func find(_ code: String) -> TieredOutreachPolicy?
        func save(_ item: TieredOutreachPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [TieredOutreachPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredOutreachPolicyStore: TieredOutreachPolicyStore {
        var items: [String: TieredOutreachPolicy]
        var order: [String]

        init(items: [String: TieredOutreachPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredOutreachPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredOutreachPolicy) {
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

        func list() -> [TieredOutreachPolicy] {
            var out: [TieredOutreachPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredOutreachPolicyStore() -> any TieredOutreachPolicyStore {
        return MemoryTieredOutreachPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredOutreachPolicyStore: TieredOutreachPolicyStore {
        var inner: MemoryTieredOutreachPolicyStore
        var cache: TTLCache<TieredOutreachPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredOutreachPolicyStore, cache: TTLCache<TieredOutreachPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredOutreachPolicy? {
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

        func save(_ item: TieredOutreachPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredOutreachPolicy] {
            return inner.list()
        }
    }

    static func newCachedTieredOutreachPolicyStore(_ inner: MemoryTieredOutreachPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredOutreachPolicyStore {
        return CachedTieredOutreachPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered outreach policies. Empty fields match all.
    final class TieredOutreachPolicyQuery {
        var category: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredOutreachPolicy) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredOutreachPolicy]) -> [TieredOutreachPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredOutreachPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredOutreachPolicies(_ store: any TieredOutreachPolicyStore, query: TieredOutreachPolicyQuery) -> [TieredOutreachPolicy] {
        return query.apply(store.list())
    }
}
