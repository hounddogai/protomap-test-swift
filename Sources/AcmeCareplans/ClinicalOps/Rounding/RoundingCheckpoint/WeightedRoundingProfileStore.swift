import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted rounding profiles by code.
    protocol WeightedRoundingProfileStore {
        func find(_ code: String) -> WeightedRoundingProfile?
        func save(_ item: WeightedRoundingProfile)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedRoundingProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedRoundingProfileStore: WeightedRoundingProfileStore {
        var items: [String: WeightedRoundingProfile]
        var order: [String]

        init(items: [String: WeightedRoundingProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedRoundingProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedRoundingProfile) {
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

        func list() -> [WeightedRoundingProfile] {
            var out: [WeightedRoundingProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedRoundingProfileStore() -> any WeightedRoundingProfileStore {
        return MemoryWeightedRoundingProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedRoundingProfileStore: WeightedRoundingProfileStore {
        var inner: MemoryWeightedRoundingProfileStore
        var cache: TTLCache<WeightedRoundingProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedRoundingProfileStore, cache: TTLCache<WeightedRoundingProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedRoundingProfile? {
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

        func save(_ item: WeightedRoundingProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedRoundingProfile] {
            return inner.list()
        }
    }

    static func newCachedWeightedRoundingProfileStore(_ inner: MemoryWeightedRoundingProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedRoundingProfileStore {
        return CachedWeightedRoundingProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted rounding profiles. Empty fields match all.
    final class WeightedRoundingProfileQuery {
        var category: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedRoundingProfile) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [WeightedRoundingProfile]) -> [WeightedRoundingProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedRoundingProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedRoundingProfiles(_ store: any WeightedRoundingProfileStore, query: WeightedRoundingProfileQuery) -> [WeightedRoundingProfile] {
        return query.apply(store.list())
    }
}
