import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning profiles by code.
    protocol CleaningProfileStore {
        func find(_ code: String) -> CleaningProfile?
        func save(_ item: CleaningProfile)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningProfileStore: CleaningProfileStore {
        var items: [String: CleaningProfile]
        var order: [String]

        init(items: [String: CleaningProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningProfile) {
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

        func list() -> [CleaningProfile] {
            var out: [CleaningProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningProfileStore() -> any CleaningProfileStore {
        return MemoryCleaningProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningProfileStore: CleaningProfileStore {
        var inner: MemoryCleaningProfileStore
        var cache: TTLCache<CleaningProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningProfileStore, cache: TTLCache<CleaningProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningProfile? {
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

        func save(_ item: CleaningProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningProfile] {
            return inner.list()
        }
    }

    static func newCachedCleaningProfileStore(_ inner: MemoryCleaningProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningProfileStore {
        return CachedCleaningProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning profiles. Empty fields match all.
    final class CleaningProfileQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningProfile]) -> [CleaningProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningProfiles(_ store: any CleaningProfileStore, query: CleaningProfileQuery) -> [CleaningProfile] {
        return query.apply(store.list())
    }
}
