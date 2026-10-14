import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient shift quotas by code.
    protocol LenientShiftQuotaStore {
        func find(_ code: String) -> LenientShiftQuota?
        func save(_ item: LenientShiftQuota)
        func remove(_ code: String) -> Bool
        func list() -> [LenientShiftQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientShiftQuotaStore: LenientShiftQuotaStore {
        var items: [String: LenientShiftQuota]
        var order: [String]

        init(items: [String: LenientShiftQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientShiftQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientShiftQuota) {
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

        func list() -> [LenientShiftQuota] {
            var out: [LenientShiftQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientShiftQuotaStore() -> any LenientShiftQuotaStore {
        return MemoryLenientShiftQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientShiftQuotaStore: LenientShiftQuotaStore {
        var inner: MemoryLenientShiftQuotaStore
        var cache: TTLCache<LenientShiftQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientShiftQuotaStore, cache: TTLCache<LenientShiftQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientShiftQuota? {
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

        func save(_ item: LenientShiftQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientShiftQuota] {
            return inner.list()
        }
    }

    static func newCachedLenientShiftQuotaStore(_ inner: MemoryLenientShiftQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientShiftQuotaStore {
        return CachedLenientShiftQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient shift quotas. Empty fields match all.
    final class LenientShiftQuotaQuery {
        var facility: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientShiftQuota) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientShiftQuota]) -> [LenientShiftQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientShiftQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientShiftQuotas(_ store: any LenientShiftQuotaStore, query: LenientShiftQuotaQuery) -> [LenientShiftQuota] {
        return query.apply(store.list())
    }
}
