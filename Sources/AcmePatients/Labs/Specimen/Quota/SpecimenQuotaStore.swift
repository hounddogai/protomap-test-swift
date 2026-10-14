import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen quotas by code.
    protocol SpecimenQuotaStore {
        func find(_ code: String) -> SpecimenQuota?
        func save(_ item: SpecimenQuota)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenQuotaStore: SpecimenQuotaStore {
        var items: [String: SpecimenQuota]
        var order: [String]

        init(items: [String: SpecimenQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenQuota) {
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

        func list() -> [SpecimenQuota] {
            var out: [SpecimenQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenQuotaStore() -> any SpecimenQuotaStore {
        return MemorySpecimenQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenQuotaStore: SpecimenQuotaStore {
        var inner: MemorySpecimenQuotaStore
        var cache: TTLCache<SpecimenQuota>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenQuotaStore, cache: TTLCache<SpecimenQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenQuota? {
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

        func save(_ item: SpecimenQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenQuota] {
            return inner.list()
        }
    }

    static func newCachedSpecimenQuotaStore(_ inner: MemorySpecimenQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenQuotaStore {
        return CachedSpecimenQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen quotas. Empty fields match all.
    final class SpecimenQuotaQuery {
        var facility: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCost: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenQuota) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenQuota]) -> [SpecimenQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenQuotas(_ store: any SpecimenQuotaStore, query: SpecimenQuotaQuery) -> [SpecimenQuota] {
        return query.apply(store.list())
    }
}
