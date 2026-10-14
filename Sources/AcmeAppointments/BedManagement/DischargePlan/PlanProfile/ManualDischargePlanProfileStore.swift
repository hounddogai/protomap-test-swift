import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual discharge plan profiles by code.
    protocol ManualDischargePlanProfileStore {
        func find(_ code: String) -> ManualDischargePlanProfile?
        func save(_ item: ManualDischargePlanProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDischargePlanProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDischargePlanProfileStore: ManualDischargePlanProfileStore {
        var items: [String: ManualDischargePlanProfile]
        var order: [String]

        init(items: [String: ManualDischargePlanProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDischargePlanProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDischargePlanProfile) {
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

        func list() -> [ManualDischargePlanProfile] {
            var out: [ManualDischargePlanProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDischargePlanProfileStore() -> any ManualDischargePlanProfileStore {
        return MemoryManualDischargePlanProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDischargePlanProfileStore: ManualDischargePlanProfileStore {
        var inner: MemoryManualDischargePlanProfileStore
        var cache: TTLCache<ManualDischargePlanProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDischargePlanProfileStore, cache: TTLCache<ManualDischargePlanProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDischargePlanProfile? {
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

        func save(_ item: ManualDischargePlanProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDischargePlanProfile] {
            return inner.list()
        }
    }

    static func newCachedManualDischargePlanProfileStore(_ inner: MemoryManualDischargePlanProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDischargePlanProfileStore {
        return CachedManualDischargePlanProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual discharge plan profiles. Empty fields match all.
    final class ManualDischargePlanProfileQuery {
        var source: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDischargePlanProfile) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualDischargePlanProfile]) -> [ManualDischargePlanProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDischargePlanProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDischargePlanProfiles(_ store: any ManualDischargePlanProfileStore, query: ManualDischargePlanProfileQuery) -> [ManualDischargePlanProfile] {
        return query.apply(store.list())
    }
}
