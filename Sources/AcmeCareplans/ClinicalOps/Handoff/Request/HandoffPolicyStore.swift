import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff policies by code.
    protocol HandoffPolicyStore {
        func find(_ code: String) -> HandoffPolicy?
        func save(_ item: HandoffPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffPolicyStore: HandoffPolicyStore {
        var items: [String: HandoffPolicy]
        var order: [String]

        init(items: [String: HandoffPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffPolicy) {
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

        func list() -> [HandoffPolicy] {
            var out: [HandoffPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffPolicyStore() -> any HandoffPolicyStore {
        return MemoryHandoffPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffPolicyStore: HandoffPolicyStore {
        var inner: MemoryHandoffPolicyStore
        var cache: TTLCache<HandoffPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffPolicyStore, cache: TTLCache<HandoffPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffPolicy? {
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

        func save(_ item: HandoffPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffPolicy] {
            return inner.list()
        }
    }

    static func newCachedHandoffPolicyStore(_ inner: MemoryHandoffPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffPolicyStore {
        return CachedHandoffPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff policies. Empty fields match all.
    final class HandoffPolicyQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffPolicy) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [HandoffPolicy]) -> [HandoffPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffPolicies(_ store: any HandoffPolicyStore, query: HandoffPolicyQuery) -> [HandoffPolicy] {
        return query.apply(store.list())
    }
}
