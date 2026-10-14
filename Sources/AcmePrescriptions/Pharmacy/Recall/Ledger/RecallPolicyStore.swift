import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall policies by code.
    protocol RecallPolicyStore {
        func find(_ code: String) -> RecallPolicy?
        func save(_ item: RecallPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [RecallPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallPolicyStore: RecallPolicyStore {
        var items: [String: RecallPolicy]
        var order: [String]

        init(items: [String: RecallPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallPolicy) {
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

        func list() -> [RecallPolicy] {
            var out: [RecallPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallPolicyStore() -> any RecallPolicyStore {
        return MemoryRecallPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallPolicyStore: RecallPolicyStore {
        var inner: MemoryRecallPolicyStore
        var cache: TTLCache<RecallPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallPolicyStore, cache: TTLCache<RecallPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallPolicy? {
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

        func save(_ item: RecallPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallPolicy] {
            return inner.list()
        }
    }

    static func newCachedRecallPolicyStore(_ inner: MemoryRecallPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallPolicyStore {
        return CachedRecallPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall policies. Empty fields match all.
    final class RecallPolicyQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallPolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallPolicy]) -> [RecallPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallPolicies(_ store: any RecallPolicyStore, query: RecallPolicyQuery) -> [RecallPolicy] {
        return query.apply(store.list())
    }
}
