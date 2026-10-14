import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol quotas by code.
    protocol CareProtocolQuotaStore {
        func find(_ code: String) -> CareProtocolQuota?
        func save(_ item: CareProtocolQuota)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolQuotaStore: CareProtocolQuotaStore {
        var items: [String: CareProtocolQuota]
        var order: [String]

        init(items: [String: CareProtocolQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolQuota) {
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

        func list() -> [CareProtocolQuota] {
            var out: [CareProtocolQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolQuotaStore() -> any CareProtocolQuotaStore {
        return MemoryCareProtocolQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolQuotaStore: CareProtocolQuotaStore {
        var inner: MemoryCareProtocolQuotaStore
        var cache: TTLCache<CareProtocolQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolQuotaStore, cache: TTLCache<CareProtocolQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolQuota? {
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

        func save(_ item: CareProtocolQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolQuota] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolQuotaStore(_ inner: MemoryCareProtocolQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolQuotaStore {
        return CachedCareProtocolQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol quotas. Empty fields match all.
    final class CareProtocolQuotaQuery {
        var source: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolQuota) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolQuota]) -> [CareProtocolQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolQuotas(_ store: any CareProtocolQuotaStore, query: CareProtocolQuotaQuery) -> [CareProtocolQuota] {
        return query.apply(store.list())
    }
}
