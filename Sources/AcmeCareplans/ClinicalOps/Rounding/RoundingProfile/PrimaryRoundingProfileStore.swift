import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary rounding profiles by code.
    protocol PrimaryRoundingProfileStore {
        func find(_ code: String) -> PrimaryRoundingProfile?
        func save(_ item: PrimaryRoundingProfile)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRoundingProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRoundingProfileStore: PrimaryRoundingProfileStore {
        var items: [String: PrimaryRoundingProfile]
        var order: [String]

        init(items: [String: PrimaryRoundingProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRoundingProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRoundingProfile) {
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

        func list() -> [PrimaryRoundingProfile] {
            var out: [PrimaryRoundingProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRoundingProfileStore() -> any PrimaryRoundingProfileStore {
        return MemoryPrimaryRoundingProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRoundingProfileStore: PrimaryRoundingProfileStore {
        var inner: MemoryPrimaryRoundingProfileStore
        var cache: TTLCache<PrimaryRoundingProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRoundingProfileStore, cache: TTLCache<PrimaryRoundingProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRoundingProfile? {
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

        func save(_ item: PrimaryRoundingProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRoundingProfile] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRoundingProfileStore(_ inner: MemoryPrimaryRoundingProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRoundingProfileStore {
        return CachedPrimaryRoundingProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary rounding profiles. Empty fields match all.
    final class PrimaryRoundingProfileQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRoundingProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryRoundingProfile]) -> [PrimaryRoundingProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRoundingProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRoundingProfiles(_ store: any PrimaryRoundingProfileStore, query: PrimaryRoundingProfileQuery) -> [PrimaryRoundingProfile] {
        return query.apply(store.list())
    }
}
