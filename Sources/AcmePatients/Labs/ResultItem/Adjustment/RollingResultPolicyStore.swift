import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling result policies by code.
    protocol RollingResultPolicyStore {
        func find(_ code: String) -> RollingResultPolicy?
        func save(_ item: RollingResultPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [RollingResultPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingResultPolicyStore: RollingResultPolicyStore {
        var items: [String: RollingResultPolicy]
        var order: [String]

        init(items: [String: RollingResultPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingResultPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingResultPolicy) {
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

        func list() -> [RollingResultPolicy] {
            var out: [RollingResultPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingResultPolicyStore() -> any RollingResultPolicyStore {
        return MemoryRollingResultPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingResultPolicyStore: RollingResultPolicyStore {
        var inner: MemoryRollingResultPolicyStore
        var cache: TTLCache<RollingResultPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingResultPolicyStore, cache: TTLCache<RollingResultPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingResultPolicy? {
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

        func save(_ item: RollingResultPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingResultPolicy] {
            return inner.list()
        }
    }

    static func newCachedRollingResultPolicyStore(_ inner: MemoryRollingResultPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingResultPolicyStore {
        return CachedRollingResultPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling result policies. Empty fields match all.
    final class RollingResultPolicyQuery {
        var unit: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingResultPolicy) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RollingResultPolicy]) -> [RollingResultPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingResultPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingResultPolicies(_ store: any RollingResultPolicyStore, query: RollingResultPolicyQuery) -> [RollingResultPolicy] {
        return query.apply(store.list())
    }
}
