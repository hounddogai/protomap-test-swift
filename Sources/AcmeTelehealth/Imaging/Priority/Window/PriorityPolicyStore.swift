import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority policies by code.
    protocol PriorityPolicyStore {
        func find(_ code: String) -> PriorityPolicy?
        func save(_ item: PriorityPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityPolicyStore: PriorityPolicyStore {
        var items: [String: PriorityPolicy]
        var order: [String]

        init(items: [String: PriorityPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityPolicy) {
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

        func list() -> [PriorityPolicy] {
            var out: [PriorityPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityPolicyStore() -> any PriorityPolicyStore {
        return MemoryPriorityPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityPolicyStore: PriorityPolicyStore {
        var inner: MemoryPriorityPolicyStore
        var cache: TTLCache<PriorityPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityPolicyStore, cache: TTLCache<PriorityPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityPolicy? {
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

        func save(_ item: PriorityPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityPolicy] {
            return inner.list()
        }
    }

    static func newCachedPriorityPolicyStore(_ inner: MemoryPriorityPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityPolicyStore {
        return CachedPriorityPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority policies. Empty fields match all.
    final class PriorityPolicyQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityPolicy) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [PriorityPolicy]) -> [PriorityPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityPolicies(_ store: any PriorityPolicyStore, query: PriorityPolicyQuery) -> [PriorityPolicy] {
        return query.apply(store.list())
    }
}
