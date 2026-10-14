import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted claim profiles by code.
    protocol WeightedClaimProfileStore {
        func find(_ code: String) -> WeightedClaimProfile?
        func save(_ item: WeightedClaimProfile)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedClaimProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedClaimProfileStore: WeightedClaimProfileStore {
        var items: [String: WeightedClaimProfile]
        var order: [String]

        init(items: [String: WeightedClaimProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedClaimProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedClaimProfile) {
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

        func list() -> [WeightedClaimProfile] {
            var out: [WeightedClaimProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedClaimProfileStore() -> any WeightedClaimProfileStore {
        return MemoryWeightedClaimProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedClaimProfileStore: WeightedClaimProfileStore {
        var inner: MemoryWeightedClaimProfileStore
        var cache: TTLCache<WeightedClaimProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedClaimProfileStore, cache: TTLCache<WeightedClaimProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedClaimProfile? {
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

        func save(_ item: WeightedClaimProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedClaimProfile] {
            return inner.list()
        }
    }

    static func newCachedWeightedClaimProfileStore(_ inner: MemoryWeightedClaimProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedClaimProfileStore {
        return CachedWeightedClaimProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted claim profiles. Empty fields match all.
    final class WeightedClaimProfileQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedClaimProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedClaimProfile]) -> [WeightedClaimProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedClaimProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedClaimProfiles(_ store: any WeightedClaimProfileStore, query: WeightedClaimProfileQuery) -> [WeightedClaimProfile] {
        return query.apply(store.list())
    }
}
