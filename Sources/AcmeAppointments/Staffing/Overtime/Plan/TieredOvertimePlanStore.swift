import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered overtime plans by code.
    protocol TieredOvertimePlanStore {
        func find(_ code: String) -> TieredOvertimePlan?
        func save(_ item: TieredOvertimePlan)
        func remove(_ code: String) -> Bool
        func list() -> [TieredOvertimePlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredOvertimePlanStore: TieredOvertimePlanStore {
        var items: [String: TieredOvertimePlan]
        var order: [String]

        init(items: [String: TieredOvertimePlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredOvertimePlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredOvertimePlan) {
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

        func list() -> [TieredOvertimePlan] {
            var out: [TieredOvertimePlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredOvertimePlanStore() -> any TieredOvertimePlanStore {
        return MemoryTieredOvertimePlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredOvertimePlanStore: TieredOvertimePlanStore {
        var inner: MemoryTieredOvertimePlanStore
        var cache: TTLCache<TieredOvertimePlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredOvertimePlanStore, cache: TTLCache<TieredOvertimePlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredOvertimePlan? {
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

        func save(_ item: TieredOvertimePlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredOvertimePlan] {
            return inner.list()
        }
    }

    static func newCachedTieredOvertimePlanStore(_ inner: MemoryTieredOvertimePlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredOvertimePlanStore {
        return CachedTieredOvertimePlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered overtime plans. Empty fields match all.
    final class TieredOvertimePlanQuery {
        var ward: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredOvertimePlan) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredOvertimePlan]) -> [TieredOvertimePlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredOvertimePlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredOvertimePlans(_ store: any TieredOvertimePlanStore, query: TieredOvertimePlanQuery) -> [TieredOvertimePlan] {
        return query.apply(store.list())
    }
}
