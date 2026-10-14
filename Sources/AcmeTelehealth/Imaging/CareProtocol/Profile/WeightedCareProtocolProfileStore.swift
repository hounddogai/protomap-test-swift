import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps weighted care protocol profiles by code.
    protocol WeightedCareProtocolProfileStore {
        func find(_ code: String) -> WeightedCareProtocolProfile?
        func save(_ item: WeightedCareProtocolProfile)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCareProtocolProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCareProtocolProfileStore: WeightedCareProtocolProfileStore {
        var items: [String: WeightedCareProtocolProfile]
        var order: [String]

        init(items: [String: WeightedCareProtocolProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCareProtocolProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCareProtocolProfile) {
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

        func list() -> [WeightedCareProtocolProfile] {
            var out: [WeightedCareProtocolProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCareProtocolProfileStore() -> any WeightedCareProtocolProfileStore {
        return MemoryWeightedCareProtocolProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCareProtocolProfileStore: WeightedCareProtocolProfileStore {
        var inner: MemoryWeightedCareProtocolProfileStore
        var cache: TTLCache<WeightedCareProtocolProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCareProtocolProfileStore, cache: TTLCache<WeightedCareProtocolProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCareProtocolProfile? {
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

        func save(_ item: WeightedCareProtocolProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCareProtocolProfile] {
            return inner.list()
        }
    }

    static func newCachedWeightedCareProtocolProfileStore(_ inner: MemoryWeightedCareProtocolProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCareProtocolProfileStore {
        return CachedWeightedCareProtocolProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted care protocol profiles. Empty fields match all.
    final class WeightedCareProtocolProfileQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCareProtocolProfile) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCareProtocolProfile]) -> [WeightedCareProtocolProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCareProtocolProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCareProtocolProfiles(_ store: any WeightedCareProtocolProfileStore, query: WeightedCareProtocolProfileQuery) -> [WeightedCareProtocolProfile] {
        return query.apply(store.list())
    }
}
