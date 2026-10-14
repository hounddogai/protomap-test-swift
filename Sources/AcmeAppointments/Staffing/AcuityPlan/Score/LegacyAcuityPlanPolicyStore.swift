import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy acuity plan policies by code.
    protocol LegacyAcuityPlanPolicyStore {
        func find(_ code: String) -> LegacyAcuityPlanPolicy?
        func save(_ item: LegacyAcuityPlanPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAcuityPlanPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAcuityPlanPolicyStore: LegacyAcuityPlanPolicyStore {
        var items: [String: LegacyAcuityPlanPolicy]
        var order: [String]

        init(items: [String: LegacyAcuityPlanPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAcuityPlanPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAcuityPlanPolicy) {
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

        func list() -> [LegacyAcuityPlanPolicy] {
            var out: [LegacyAcuityPlanPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAcuityPlanPolicyStore() -> any LegacyAcuityPlanPolicyStore {
        return MemoryLegacyAcuityPlanPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAcuityPlanPolicyStore: LegacyAcuityPlanPolicyStore {
        var inner: MemoryLegacyAcuityPlanPolicyStore
        var cache: TTLCache<LegacyAcuityPlanPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAcuityPlanPolicyStore, cache: TTLCache<LegacyAcuityPlanPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAcuityPlanPolicy? {
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

        func save(_ item: LegacyAcuityPlanPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAcuityPlanPolicy] {
            return inner.list()
        }
    }

    static func newCachedLegacyAcuityPlanPolicyStore(_ inner: MemoryLegacyAcuityPlanPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAcuityPlanPolicyStore {
        return CachedLegacyAcuityPlanPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy acuity plan policies. Empty fields match all.
    final class LegacyAcuityPlanPolicyQuery {
        var locale: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAcuityPlanPolicy) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [LegacyAcuityPlanPolicy]) -> [LegacyAcuityPlanPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAcuityPlanPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAcuityPlanPolicies(_ store: any LegacyAcuityPlanPolicyStore, query: LegacyAcuityPlanPolicyQuery) -> [LegacyAcuityPlanPolicy] {
        return query.apply(store.list())
    }
}
