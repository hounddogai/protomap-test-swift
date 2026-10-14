import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped care gap quotas by code.
    protocol CappedCareGapQuotaStore {
        func find(_ code: String) -> CappedCareGapQuota?
        func save(_ item: CappedCareGapQuota)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCareGapQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCareGapQuotaStore: CappedCareGapQuotaStore {
        var items: [String: CappedCareGapQuota]
        var order: [String]

        init(items: [String: CappedCareGapQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCareGapQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCareGapQuota) {
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

        func list() -> [CappedCareGapQuota] {
            var out: [CappedCareGapQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCareGapQuotaStore() -> any CappedCareGapQuotaStore {
        return MemoryCappedCareGapQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCareGapQuotaStore: CappedCareGapQuotaStore {
        var inner: MemoryCappedCareGapQuotaStore
        var cache: TTLCache<CappedCareGapQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCareGapQuotaStore, cache: TTLCache<CappedCareGapQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCareGapQuota? {
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

        func save(_ item: CappedCareGapQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCareGapQuota] {
            return inner.list()
        }
    }

    static func newCachedCappedCareGapQuotaStore(_ inner: MemoryCappedCareGapQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCareGapQuotaStore {
        return CachedCappedCareGapQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped care gap quotas. Empty fields match all.
    final class CappedCareGapQuotaQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCareGapQuota) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCareGapQuota]) -> [CappedCareGapQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCareGapQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCareGapQuotas(_ store: any CappedCareGapQuotaStore, query: CappedCareGapQuotaQuery) -> [CappedCareGapQuota] {
        return query.apply(store.list())
    }
}
