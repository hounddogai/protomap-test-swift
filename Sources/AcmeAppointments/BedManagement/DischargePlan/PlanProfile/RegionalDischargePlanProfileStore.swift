import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional discharge plan profiles by code.
    protocol RegionalDischargePlanProfileStore {
        func find(_ code: String) -> RegionalDischargePlanProfile?
        func save(_ item: RegionalDischargePlanProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalDischargePlanProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalDischargePlanProfileStore: RegionalDischargePlanProfileStore {
        var items: [String: RegionalDischargePlanProfile]
        var order: [String]

        init(items: [String: RegionalDischargePlanProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalDischargePlanProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalDischargePlanProfile) {
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

        func list() -> [RegionalDischargePlanProfile] {
            var out: [RegionalDischargePlanProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalDischargePlanProfileStore() -> any RegionalDischargePlanProfileStore {
        return MemoryRegionalDischargePlanProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalDischargePlanProfileStore: RegionalDischargePlanProfileStore {
        var inner: MemoryRegionalDischargePlanProfileStore
        var cache: TTLCache<RegionalDischargePlanProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalDischargePlanProfileStore, cache: TTLCache<RegionalDischargePlanProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalDischargePlanProfile? {
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

        func save(_ item: RegionalDischargePlanProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalDischargePlanProfile] {
            return inner.list()
        }
    }

    static func newCachedRegionalDischargePlanProfileStore(_ inner: MemoryRegionalDischargePlanProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalDischargePlanProfileStore {
        return CachedRegionalDischargePlanProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional discharge plan profiles. Empty fields match all.
    final class RegionalDischargePlanProfileQuery {
        var region: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRatio: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalDischargePlanProfile) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalDischargePlanProfile]) -> [RegionalDischargePlanProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalDischargePlanProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalDischargePlanProfiles(_ store: any RegionalDischargePlanProfileStore, query: RegionalDischargePlanProfileQuery) -> [RegionalDischargePlanProfile] {
        return query.apply(store.list())
    }
}
