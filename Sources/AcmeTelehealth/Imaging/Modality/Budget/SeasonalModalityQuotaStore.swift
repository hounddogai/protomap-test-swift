import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal modality quotas by code.
    protocol SeasonalModalityQuotaStore {
        func find(_ code: String) -> SeasonalModalityQuota?
        func save(_ item: SeasonalModalityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalModalityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalModalityQuotaStore: SeasonalModalityQuotaStore {
        var items: [String: SeasonalModalityQuota]
        var order: [String]

        init(items: [String: SeasonalModalityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalModalityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalModalityQuota) {
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

        func list() -> [SeasonalModalityQuota] {
            var out: [SeasonalModalityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalModalityQuotaStore() -> any SeasonalModalityQuotaStore {
        return MemorySeasonalModalityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalModalityQuotaStore: SeasonalModalityQuotaStore {
        var inner: MemorySeasonalModalityQuotaStore
        var cache: TTLCache<SeasonalModalityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalModalityQuotaStore, cache: TTLCache<SeasonalModalityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalModalityQuota? {
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

        func save(_ item: SeasonalModalityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalModalityQuota] {
            return inner.list()
        }
    }

    static func newCachedSeasonalModalityQuotaStore(_ inner: MemorySeasonalModalityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalModalityQuotaStore {
        return CachedSeasonalModalityQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal modality quotas. Empty fields match all.
    final class SeasonalModalityQuotaQuery {
        var category: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalModalityQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [SeasonalModalityQuota]) -> [SeasonalModalityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalModalityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalModalityQuotas(_ store: any SeasonalModalityQuotaStore, query: SeasonalModalityQuotaQuery) -> [SeasonalModalityQuota] {
        return query.apply(store.list())
    }
}
