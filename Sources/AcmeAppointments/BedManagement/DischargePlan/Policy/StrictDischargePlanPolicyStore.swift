import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict discharge plan policies by code.
    protocol StrictDischargePlanPolicyStore {
        func find(_ code: String) -> StrictDischargePlanPolicy?
        func save(_ item: StrictDischargePlanPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [StrictDischargePlanPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictDischargePlanPolicyStore: StrictDischargePlanPolicyStore {
        var items: [String: StrictDischargePlanPolicy]
        var order: [String]

        init(items: [String: StrictDischargePlanPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictDischargePlanPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictDischargePlanPolicy) {
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

        func list() -> [StrictDischargePlanPolicy] {
            var out: [StrictDischargePlanPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictDischargePlanPolicyStore() -> any StrictDischargePlanPolicyStore {
        return MemoryStrictDischargePlanPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictDischargePlanPolicyStore: StrictDischargePlanPolicyStore {
        var inner: MemoryStrictDischargePlanPolicyStore
        var cache: TTLCache<StrictDischargePlanPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictDischargePlanPolicyStore, cache: TTLCache<StrictDischargePlanPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictDischargePlanPolicy? {
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

        func save(_ item: StrictDischargePlanPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictDischargePlanPolicy] {
            return inner.list()
        }
    }

    static func newCachedStrictDischargePlanPolicyStore(_ inner: MemoryStrictDischargePlanPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictDischargePlanPolicyStore {
        return CachedStrictDischargePlanPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict discharge plan policies. Empty fields match all.
    final class StrictDischargePlanPolicyQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictDischargePlanPolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [StrictDischargePlanPolicy]) -> [StrictDischargePlanPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictDischargePlanPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictDischargePlanPolicies(_ store: any StrictDischargePlanPolicyStore, query: StrictDischargePlanPolicyQuery) -> [StrictDischargePlanPolicy] {
        return query.apply(store.list())
    }
}
