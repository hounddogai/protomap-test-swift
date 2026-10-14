import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional overtime plans by code.
    protocol RegionalOvertimePlanStore {
        func find(_ code: String) -> RegionalOvertimePlan?
        func save(_ item: RegionalOvertimePlan)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalOvertimePlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalOvertimePlanStore: RegionalOvertimePlanStore {
        var items: [String: RegionalOvertimePlan]
        var order: [String]

        init(items: [String: RegionalOvertimePlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalOvertimePlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalOvertimePlan) {
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

        func list() -> [RegionalOvertimePlan] {
            var out: [RegionalOvertimePlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalOvertimePlanStore() -> any RegionalOvertimePlanStore {
        return MemoryRegionalOvertimePlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalOvertimePlanStore: RegionalOvertimePlanStore {
        var inner: MemoryRegionalOvertimePlanStore
        var cache: TTLCache<RegionalOvertimePlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalOvertimePlanStore, cache: TTLCache<RegionalOvertimePlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalOvertimePlan? {
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

        func save(_ item: RegionalOvertimePlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalOvertimePlan] {
            return inner.list()
        }
    }

    static func newCachedRegionalOvertimePlanStore(_ inner: MemoryRegionalOvertimePlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalOvertimePlanStore {
        return CachedRegionalOvertimePlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional overtime plans. Empty fields match all.
    final class RegionalOvertimePlanQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalOvertimePlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalOvertimePlan]) -> [RegionalOvertimePlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalOvertimePlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalOvertimePlans(_ store: any RegionalOvertimePlanStore, query: RegionalOvertimePlanQuery) -> [RegionalOvertimePlan] {
        return query.apply(store.list())
    }
}
