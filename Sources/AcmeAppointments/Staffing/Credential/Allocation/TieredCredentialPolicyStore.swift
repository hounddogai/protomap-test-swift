import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered credential policies by code.
    protocol TieredCredentialPolicyStore {
        func find(_ code: String) -> TieredCredentialPolicy?
        func save(_ item: TieredCredentialPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCredentialPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCredentialPolicyStore: TieredCredentialPolicyStore {
        var items: [String: TieredCredentialPolicy]
        var order: [String]

        init(items: [String: TieredCredentialPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCredentialPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCredentialPolicy) {
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

        func list() -> [TieredCredentialPolicy] {
            var out: [TieredCredentialPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCredentialPolicyStore() -> any TieredCredentialPolicyStore {
        return MemoryTieredCredentialPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCredentialPolicyStore: TieredCredentialPolicyStore {
        var inner: MemoryTieredCredentialPolicyStore
        var cache: TTLCache<TieredCredentialPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCredentialPolicyStore, cache: TTLCache<TieredCredentialPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCredentialPolicy? {
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

        func save(_ item: TieredCredentialPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCredentialPolicy] {
            return inner.list()
        }
    }

    static func newCachedTieredCredentialPolicyStore(_ inner: MemoryTieredCredentialPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCredentialPolicyStore {
        return CachedTieredCredentialPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered credential policies. Empty fields match all.
    final class TieredCredentialPolicyQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCredentialPolicy) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCredentialPolicy]) -> [TieredCredentialPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCredentialPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCredentialPolicies(_ store: any TieredCredentialPolicyStore, query: TieredCredentialPolicyQuery) -> [TieredCredentialPolicy] {
        return query.apply(store.list())
    }
}
