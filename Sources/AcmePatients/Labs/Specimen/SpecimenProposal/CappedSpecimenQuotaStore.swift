import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped specimen quotas by code.
    protocol CappedSpecimenQuotaStore {
        func find(_ code: String) -> CappedSpecimenQuota?
        func save(_ item: CappedSpecimenQuota)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSpecimenQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSpecimenQuotaStore: CappedSpecimenQuotaStore {
        var items: [String: CappedSpecimenQuota]
        var order: [String]

        init(items: [String: CappedSpecimenQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSpecimenQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSpecimenQuota) {
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

        func list() -> [CappedSpecimenQuota] {
            var out: [CappedSpecimenQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSpecimenQuotaStore() -> any CappedSpecimenQuotaStore {
        return MemoryCappedSpecimenQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSpecimenQuotaStore: CappedSpecimenQuotaStore {
        var inner: MemoryCappedSpecimenQuotaStore
        var cache: TTLCache<CappedSpecimenQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSpecimenQuotaStore, cache: TTLCache<CappedSpecimenQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSpecimenQuota? {
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

        func save(_ item: CappedSpecimenQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSpecimenQuota] {
            return inner.list()
        }
    }

    static func newCachedCappedSpecimenQuotaStore(_ inner: MemoryCappedSpecimenQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSpecimenQuotaStore {
        return CachedCappedSpecimenQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped specimen quotas. Empty fields match all.
    final class CappedSpecimenQuotaQuery {
        var segment: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSpecimenQuota) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedSpecimenQuota]) -> [CappedSpecimenQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSpecimenQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSpecimenQuotas(_ store: any CappedSpecimenQuotaStore, query: CappedSpecimenQuotaQuery) -> [CappedSpecimenQuota] {
        return query.apply(store.list())
    }
}
