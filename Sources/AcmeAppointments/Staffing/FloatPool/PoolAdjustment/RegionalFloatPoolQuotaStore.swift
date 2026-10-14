import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional float pool quotas by code.
    protocol RegionalFloatPoolQuotaStore {
        func find(_ code: String) -> RegionalFloatPoolQuota?
        func save(_ item: RegionalFloatPoolQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalFloatPoolQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalFloatPoolQuotaStore: RegionalFloatPoolQuotaStore {
        var items: [String: RegionalFloatPoolQuota]
        var order: [String]

        init(items: [String: RegionalFloatPoolQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalFloatPoolQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalFloatPoolQuota) {
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

        func list() -> [RegionalFloatPoolQuota] {
            var out: [RegionalFloatPoolQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalFloatPoolQuotaStore() -> any RegionalFloatPoolQuotaStore {
        return MemoryRegionalFloatPoolQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalFloatPoolQuotaStore: RegionalFloatPoolQuotaStore {
        var inner: MemoryRegionalFloatPoolQuotaStore
        var cache: TTLCache<RegionalFloatPoolQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalFloatPoolQuotaStore, cache: TTLCache<RegionalFloatPoolQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalFloatPoolQuota? {
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

        func save(_ item: RegionalFloatPoolQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalFloatPoolQuota] {
            return inner.list()
        }
    }

    static func newCachedRegionalFloatPoolQuotaStore(_ inner: MemoryRegionalFloatPoolQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalFloatPoolQuotaStore {
        return CachedRegionalFloatPoolQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional float pool quotas. Empty fields match all.
    final class RegionalFloatPoolQuotaQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalFloatPoolQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RegionalFloatPoolQuota]) -> [RegionalFloatPoolQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalFloatPoolQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalFloatPoolQuotas(_ store: any RegionalFloatPoolQuotaStore, query: RegionalFloatPoolQuotaQuery) -> [RegionalFloatPoolQuota] {
        return query.apply(store.list())
    }
}
