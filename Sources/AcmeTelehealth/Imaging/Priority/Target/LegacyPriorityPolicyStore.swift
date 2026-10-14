import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy priority policies by code.
    protocol LegacyPriorityPolicyStore {
        func find(_ code: String) -> LegacyPriorityPolicy?
        func save(_ item: LegacyPriorityPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyPriorityPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyPriorityPolicyStore: LegacyPriorityPolicyStore {
        var items: [String: LegacyPriorityPolicy]
        var order: [String]

        init(items: [String: LegacyPriorityPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyPriorityPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyPriorityPolicy) {
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

        func list() -> [LegacyPriorityPolicy] {
            var out: [LegacyPriorityPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyPriorityPolicyStore() -> any LegacyPriorityPolicyStore {
        return MemoryLegacyPriorityPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyPriorityPolicyStore: LegacyPriorityPolicyStore {
        var inner: MemoryLegacyPriorityPolicyStore
        var cache: TTLCache<LegacyPriorityPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyPriorityPolicyStore, cache: TTLCache<LegacyPriorityPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyPriorityPolicy? {
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

        func save(_ item: LegacyPriorityPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyPriorityPolicy] {
            return inner.list()
        }
    }

    static func newCachedLegacyPriorityPolicyStore(_ inner: MemoryLegacyPriorityPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyPriorityPolicyStore {
        return CachedLegacyPriorityPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy priority policies. Empty fields match all.
    final class LegacyPriorityPolicyQuery {
        var source: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyPriorityPolicy) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [LegacyPriorityPolicy]) -> [LegacyPriorityPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyPriorityPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyPriorityPolicies(_ store: any LegacyPriorityPolicyStore, query: LegacyPriorityPolicyQuery) -> [LegacyPriorityPolicy] {
        return query.apply(store.list())
    }
}
