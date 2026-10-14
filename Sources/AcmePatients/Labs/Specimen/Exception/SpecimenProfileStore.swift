import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen profiles by code.
    protocol SpecimenProfileStore {
        func find(_ code: String) -> SpecimenProfile?
        func save(_ item: SpecimenProfile)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenProfileStore: SpecimenProfileStore {
        var items: [String: SpecimenProfile]
        var order: [String]

        init(items: [String: SpecimenProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenProfile) {
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

        func list() -> [SpecimenProfile] {
            var out: [SpecimenProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenProfileStore() -> any SpecimenProfileStore {
        return MemorySpecimenProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenProfileStore: SpecimenProfileStore {
        var inner: MemorySpecimenProfileStore
        var cache: TTLCache<SpecimenProfile>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenProfileStore, cache: TTLCache<SpecimenProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenProfile? {
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

        func save(_ item: SpecimenProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenProfile] {
            return inner.list()
        }
    }

    static func newCachedSpecimenProfileStore(_ inner: MemorySpecimenProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenProfileStore {
        return CachedSpecimenProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen profiles. Empty fields match all.
    final class SpecimenProfileQuery {
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

        func matches(_ item: SpecimenProfile) -> Bool {
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

        func apply(_ items: [SpecimenProfile]) -> [SpecimenProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenProfiles(_ store: any SpecimenProfileStore, query: SpecimenProfileQuery) -> [SpecimenProfile] {
        return query.apply(store.list())
    }
}
