import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure policies by code.
    protocol ClosurePolicyStore {
        func find(_ code: String) -> ClosurePolicy?
        func save(_ item: ClosurePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ClosurePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosurePolicyStore: ClosurePolicyStore {
        var items: [String: ClosurePolicy]
        var order: [String]

        init(items: [String: ClosurePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosurePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosurePolicy) {
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

        func list() -> [ClosurePolicy] {
            var out: [ClosurePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosurePolicyStore() -> any ClosurePolicyStore {
        return MemoryClosurePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosurePolicyStore: ClosurePolicyStore {
        var inner: MemoryClosurePolicyStore
        var cache: TTLCache<ClosurePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosurePolicyStore, cache: TTLCache<ClosurePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosurePolicy? {
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

        func save(_ item: ClosurePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosurePolicy] {
            return inner.list()
        }
    }

    static func newCachedClosurePolicyStore(_ inner: MemoryClosurePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosurePolicyStore {
        return CachedClosurePolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure policies. Empty fields match all.
    final class ClosurePolicyQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosurePolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosurePolicy]) -> [ClosurePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosurePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosurePolicies(_ store: any ClosurePolicyStore, query: ClosurePolicyQuery) -> [ClosurePolicy] {
        return query.apply(store.list())
    }
}
