import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy specimen profiles by code.
    protocol LegacySpecimenProfileStore {
        func find(_ code: String) -> LegacySpecimenProfile?
        func save(_ item: LegacySpecimenProfile)
        func remove(_ code: String) -> Bool
        func list() -> [LegacySpecimenProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacySpecimenProfileStore: LegacySpecimenProfileStore {
        var items: [String: LegacySpecimenProfile]
        var order: [String]

        init(items: [String: LegacySpecimenProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacySpecimenProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacySpecimenProfile) {
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

        func list() -> [LegacySpecimenProfile] {
            var out: [LegacySpecimenProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacySpecimenProfileStore() -> any LegacySpecimenProfileStore {
        return MemoryLegacySpecimenProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacySpecimenProfileStore: LegacySpecimenProfileStore {
        var inner: MemoryLegacySpecimenProfileStore
        var cache: TTLCache<LegacySpecimenProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacySpecimenProfileStore, cache: TTLCache<LegacySpecimenProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacySpecimenProfile? {
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

        func save(_ item: LegacySpecimenProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacySpecimenProfile] {
            return inner.list()
        }
    }

    static func newCachedLegacySpecimenProfileStore(_ inner: MemoryLegacySpecimenProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacySpecimenProfileStore {
        return CachedLegacySpecimenProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy specimen profiles. Empty fields match all.
    final class LegacySpecimenProfileQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacySpecimenProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacySpecimenProfile]) -> [LegacySpecimenProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacySpecimenProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacySpecimenProfiles(_ store: any LegacySpecimenProfileStore, query: LegacySpecimenProfileQuery) -> [LegacySpecimenProfile] {
        return query.apply(store.list())
    }
}
