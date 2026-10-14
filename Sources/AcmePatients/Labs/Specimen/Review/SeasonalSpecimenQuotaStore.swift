import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal specimen quotas by code.
    protocol SeasonalSpecimenQuotaStore {
        func find(_ code: String) -> SeasonalSpecimenQuota?
        func save(_ item: SeasonalSpecimenQuota)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSpecimenQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSpecimenQuotaStore: SeasonalSpecimenQuotaStore {
        var items: [String: SeasonalSpecimenQuota]
        var order: [String]

        init(items: [String: SeasonalSpecimenQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSpecimenQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSpecimenQuota) {
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

        func list() -> [SeasonalSpecimenQuota] {
            var out: [SeasonalSpecimenQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSpecimenQuotaStore() -> any SeasonalSpecimenQuotaStore {
        return MemorySeasonalSpecimenQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSpecimenQuotaStore: SeasonalSpecimenQuotaStore {
        var inner: MemorySeasonalSpecimenQuotaStore
        var cache: TTLCache<SeasonalSpecimenQuota>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSpecimenQuotaStore, cache: TTLCache<SeasonalSpecimenQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSpecimenQuota? {
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

        func save(_ item: SeasonalSpecimenQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSpecimenQuota] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSpecimenQuotaStore(_ inner: MemorySeasonalSpecimenQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSpecimenQuotaStore {
        return CachedSeasonalSpecimenQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal specimen quotas. Empty fields match all.
    final class SeasonalSpecimenQuotaQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSpecimenQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [SeasonalSpecimenQuota]) -> [SeasonalSpecimenQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSpecimenQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSpecimenQuotas(_ store: any SeasonalSpecimenQuotaStore, query: SeasonalSpecimenQuotaQuery) -> [SeasonalSpecimenQuota] {
        return query.apply(store.list())
    }
}
