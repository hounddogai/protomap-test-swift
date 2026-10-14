import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert policies by code.
    protocol AlertPolicyStore {
        func find(_ code: String) -> AlertPolicy?
        func save(_ item: AlertPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [AlertPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertPolicyStore: AlertPolicyStore {
        var items: [String: AlertPolicy]
        var order: [String]

        init(items: [String: AlertPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertPolicy) {
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

        func list() -> [AlertPolicy] {
            var out: [AlertPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertPolicyStore() -> any AlertPolicyStore {
        return MemoryAlertPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertPolicyStore: AlertPolicyStore {
        var inner: MemoryAlertPolicyStore
        var cache: TTLCache<AlertPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertPolicyStore, cache: TTLCache<AlertPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertPolicy? {
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

        func save(_ item: AlertPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertPolicy] {
            return inner.list()
        }
    }

    static func newCachedAlertPolicyStore(_ inner: MemoryAlertPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertPolicyStore {
        return CachedAlertPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert policies. Empty fields match all.
    final class AlertPolicyQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertPolicy) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertPolicy]) -> [AlertPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertPolicies(_ store: any AlertPolicyStore, query: AlertPolicyQuery) -> [AlertPolicy] {
        return query.apply(store.list())
    }
}
