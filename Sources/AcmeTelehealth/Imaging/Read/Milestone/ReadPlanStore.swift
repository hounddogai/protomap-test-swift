import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read plans by code.
    protocol ReadPlanStore {
        func find(_ code: String) -> ReadPlan?
        func save(_ item: ReadPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ReadPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadPlanStore: ReadPlanStore {
        var items: [String: ReadPlan]
        var order: [String]

        init(items: [String: ReadPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadPlan) {
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

        func list() -> [ReadPlan] {
            var out: [ReadPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadPlanStore() -> any ReadPlanStore {
        return MemoryReadPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadPlanStore: ReadPlanStore {
        var inner: MemoryReadPlanStore
        var cache: TTLCache<ReadPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadPlanStore, cache: TTLCache<ReadPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadPlan? {
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

        func save(_ item: ReadPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadPlan] {
            return inner.list()
        }
    }

    static func newCachedReadPlanStore(_ inner: MemoryReadPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadPlanStore {
        return CachedReadPlanStore(inner: inner, cache: newTTLCache(512, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects read plans. Empty fields match all.
    final class ReadPlanQuery {
        var facility: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadPlan) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [ReadPlan]) -> [ReadPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadPlans(_ store: any ReadPlanStore, query: ReadPlanQuery) -> [ReadPlan] {
        return query.apply(store.list())
    }
}
