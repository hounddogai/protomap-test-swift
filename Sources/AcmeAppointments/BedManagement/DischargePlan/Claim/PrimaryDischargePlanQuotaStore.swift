import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary discharge plan quotas by code.
    protocol PrimaryDischargePlanQuotaStore {
        func find(_ code: String) -> PrimaryDischargePlanQuota?
        func save(_ item: PrimaryDischargePlanQuota)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryDischargePlanQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryDischargePlanQuotaStore: PrimaryDischargePlanQuotaStore {
        var items: [String: PrimaryDischargePlanQuota]
        var order: [String]

        init(items: [String: PrimaryDischargePlanQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryDischargePlanQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryDischargePlanQuota) {
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

        func list() -> [PrimaryDischargePlanQuota] {
            var out: [PrimaryDischargePlanQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryDischargePlanQuotaStore() -> any PrimaryDischargePlanQuotaStore {
        return MemoryPrimaryDischargePlanQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryDischargePlanQuotaStore: PrimaryDischargePlanQuotaStore {
        var inner: MemoryPrimaryDischargePlanQuotaStore
        var cache: TTLCache<PrimaryDischargePlanQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryDischargePlanQuotaStore, cache: TTLCache<PrimaryDischargePlanQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryDischargePlanQuota? {
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

        func save(_ item: PrimaryDischargePlanQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryDischargePlanQuota] {
            return inner.list()
        }
    }

    static func newCachedPrimaryDischargePlanQuotaStore(_ inner: MemoryPrimaryDischargePlanQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryDischargePlanQuotaStore {
        return CachedPrimaryDischargePlanQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary discharge plan quotas. Empty fields match all.
    final class PrimaryDischargePlanQuotaQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryDischargePlanQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryDischargePlanQuota]) -> [PrimaryDischargePlanQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryDischargePlanQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryDischargePlanQuotas(_ store: any PrimaryDischargePlanQuotaStore, query: PrimaryDischargePlanQuotaQuery) -> [PrimaryDischargePlanQuota] {
        return query.apply(store.list())
    }
}
