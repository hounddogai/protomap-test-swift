import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential policies by code.
    protocol CredentialPolicyStore {
        func find(_ code: String) -> CredentialPolicy?
        func save(_ item: CredentialPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialPolicyStore: CredentialPolicyStore {
        var items: [String: CredentialPolicy]
        var order: [String]

        init(items: [String: CredentialPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialPolicy) {
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

        func list() -> [CredentialPolicy] {
            var out: [CredentialPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialPolicyStore() -> any CredentialPolicyStore {
        return MemoryCredentialPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialPolicyStore: CredentialPolicyStore {
        var inner: MemoryCredentialPolicyStore
        var cache: TTLCache<CredentialPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialPolicyStore, cache: TTLCache<CredentialPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialPolicy? {
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

        func save(_ item: CredentialPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialPolicy] {
            return inner.list()
        }
    }

    static func newCachedCredentialPolicyStore(_ inner: MemoryCredentialPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialPolicyStore {
        return CachedCredentialPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential policies. Empty fields match all.
    final class CredentialPolicyQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialPolicy) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialPolicy]) -> [CredentialPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialPolicies(_ store: any CredentialPolicyStore, query: CredentialPolicyQuery) -> [CredentialPolicy] {
        return query.apply(store.list())
    }
}
