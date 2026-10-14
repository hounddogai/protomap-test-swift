import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential plans by code.
    protocol CredentialPlanStore {
        func find(_ code: String) -> CredentialPlan?
        func save(_ item: CredentialPlan)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialPlanStore: CredentialPlanStore {
        var items: [String: CredentialPlan]
        var order: [String]

        init(items: [String: CredentialPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialPlan) {
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

        func list() -> [CredentialPlan] {
            var out: [CredentialPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialPlanStore() -> any CredentialPlanStore {
        return MemoryCredentialPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialPlanStore: CredentialPlanStore {
        var inner: MemoryCredentialPlanStore
        var cache: TTLCache<CredentialPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialPlanStore, cache: TTLCache<CredentialPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialPlan? {
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

        func save(_ item: CredentialPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialPlan] {
            return inner.list()
        }
    }

    static func newCachedCredentialPlanStore(_ inner: MemoryCredentialPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialPlanStore {
        return CachedCredentialPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential plans. Empty fields match all.
    final class CredentialPlanQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialPlan]) -> [CredentialPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialPlans(_ store: any CredentialPlanStore, query: CredentialPlanQuery) -> [CredentialPlan] {
        return query.apply(store.list())
    }
}
