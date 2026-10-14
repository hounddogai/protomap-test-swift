import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional handoff quotas by code.
    protocol RegionalHandoffQuotaStore {
        func find(_ code: String) -> RegionalHandoffQuota?
        func save(_ item: RegionalHandoffQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalHandoffQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalHandoffQuotaStore: RegionalHandoffQuotaStore {
        var items: [String: RegionalHandoffQuota]
        var order: [String]

        init(items: [String: RegionalHandoffQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalHandoffQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalHandoffQuota) {
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

        func list() -> [RegionalHandoffQuota] {
            var out: [RegionalHandoffQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalHandoffQuotaStore() -> any RegionalHandoffQuotaStore {
        return MemoryRegionalHandoffQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalHandoffQuotaStore: RegionalHandoffQuotaStore {
        var inner: MemoryRegionalHandoffQuotaStore
        var cache: TTLCache<RegionalHandoffQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalHandoffQuotaStore, cache: TTLCache<RegionalHandoffQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalHandoffQuota? {
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

        func save(_ item: RegionalHandoffQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalHandoffQuota] {
            return inner.list()
        }
    }

    static func newCachedRegionalHandoffQuotaStore(_ inner: MemoryRegionalHandoffQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalHandoffQuotaStore {
        return CachedRegionalHandoffQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional handoff quotas. Empty fields match all.
    final class RegionalHandoffQuotaQuery {
        var facility: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalHandoffQuota) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [RegionalHandoffQuota]) -> [RegionalHandoffQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalHandoffQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalHandoffQuotas(_ store: any RegionalHandoffQuotaStore, query: RegionalHandoffQuotaQuery) -> [RegionalHandoffQuota] {
        return query.apply(store.list())
    }
}
