import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default specimen quotas by code.
    protocol DefaultSpecimenQuotaStore {
        func find(_ code: String) -> DefaultSpecimenQuota?
        func save(_ item: DefaultSpecimenQuota)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSpecimenQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSpecimenQuotaStore: DefaultSpecimenQuotaStore {
        var items: [String: DefaultSpecimenQuota]
        var order: [String]

        init(items: [String: DefaultSpecimenQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSpecimenQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSpecimenQuota) {
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

        func list() -> [DefaultSpecimenQuota] {
            var out: [DefaultSpecimenQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSpecimenQuotaStore() -> any DefaultSpecimenQuotaStore {
        return MemoryDefaultSpecimenQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSpecimenQuotaStore: DefaultSpecimenQuotaStore {
        var inner: MemoryDefaultSpecimenQuotaStore
        var cache: TTLCache<DefaultSpecimenQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSpecimenQuotaStore, cache: TTLCache<DefaultSpecimenQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSpecimenQuota? {
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

        func save(_ item: DefaultSpecimenQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSpecimenQuota] {
            return inner.list()
        }
    }

    static func newCachedDefaultSpecimenQuotaStore(_ inner: MemoryDefaultSpecimenQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSpecimenQuotaStore {
        return CachedDefaultSpecimenQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default specimen quotas. Empty fields match all.
    final class DefaultSpecimenQuotaQuery {
        var ward: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSpecimenQuota) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [DefaultSpecimenQuota]) -> [DefaultSpecimenQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSpecimenQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSpecimenQuotas(_ store: any DefaultSpecimenQuotaStore, query: DefaultSpecimenQuotaQuery) -> [DefaultSpecimenQuota] {
        return query.apply(store.list())
    }
}
