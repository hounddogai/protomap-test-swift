import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result policies by code.
    protocol ResultPolicyStore {
        func find(_ code: String) -> ResultPolicy?
        func save(_ item: ResultPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ResultPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultPolicyStore: ResultPolicyStore {
        var items: [String: ResultPolicy]
        var order: [String]

        init(items: [String: ResultPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultPolicy) {
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

        func list() -> [ResultPolicy] {
            var out: [ResultPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultPolicyStore() -> any ResultPolicyStore {
        return MemoryResultPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultPolicyStore: ResultPolicyStore {
        var inner: MemoryResultPolicyStore
        var cache: TTLCache<ResultPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultPolicyStore, cache: TTLCache<ResultPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultPolicy? {
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

        func save(_ item: ResultPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultPolicy] {
            return inner.list()
        }
    }

    static func newCachedResultPolicyStore(_ inner: MemoryResultPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultPolicyStore {
        return CachedResultPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result policies. Empty fields match all.
    final class ResultPolicyQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultPolicy]) -> [ResultPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultPolicies(_ store: any ResultPolicyStore, query: ResultPolicyQuery) -> [ResultPolicy] {
        return query.apply(store.list())
    }
}
