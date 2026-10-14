import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps weighted read profiles by code.
    protocol WeightedReadProfileStore {
        func find(_ code: String) -> WeightedReadProfile?
        func save(_ item: WeightedReadProfile)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedReadProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedReadProfileStore: WeightedReadProfileStore {
        var items: [String: WeightedReadProfile]
        var order: [String]

        init(items: [String: WeightedReadProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedReadProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedReadProfile) {
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

        func list() -> [WeightedReadProfile] {
            var out: [WeightedReadProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedReadProfileStore() -> any WeightedReadProfileStore {
        return MemoryWeightedReadProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedReadProfileStore: WeightedReadProfileStore {
        var inner: MemoryWeightedReadProfileStore
        var cache: TTLCache<WeightedReadProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedReadProfileStore, cache: TTLCache<WeightedReadProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedReadProfile? {
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

        func save(_ item: WeightedReadProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedReadProfile] {
            return inner.list()
        }
    }

    static func newCachedWeightedReadProfileStore(_ inner: MemoryWeightedReadProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedReadProfileStore {
        return CachedWeightedReadProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted read profiles. Empty fields match all.
    final class WeightedReadProfileQuery {
        var category: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRate: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedReadProfile) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedReadProfile]) -> [WeightedReadProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedReadProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedReadProfiles(_ store: any WeightedReadProfileStore, query: WeightedReadProfileQuery) -> [WeightedReadProfile] {
        return query.apply(store.list())
    }
}
