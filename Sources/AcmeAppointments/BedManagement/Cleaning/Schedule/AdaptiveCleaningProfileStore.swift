import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive cleaning profiles by code.
    protocol AdaptiveCleaningProfileStore {
        func find(_ code: String) -> AdaptiveCleaningProfile?
        func save(_ item: AdaptiveCleaningProfile)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCleaningProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCleaningProfileStore: AdaptiveCleaningProfileStore {
        var items: [String: AdaptiveCleaningProfile]
        var order: [String]

        init(items: [String: AdaptiveCleaningProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCleaningProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCleaningProfile) {
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

        func list() -> [AdaptiveCleaningProfile] {
            var out: [AdaptiveCleaningProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCleaningProfileStore() -> any AdaptiveCleaningProfileStore {
        return MemoryAdaptiveCleaningProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCleaningProfileStore: AdaptiveCleaningProfileStore {
        var inner: MemoryAdaptiveCleaningProfileStore
        var cache: TTLCache<AdaptiveCleaningProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCleaningProfileStore, cache: TTLCache<AdaptiveCleaningProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCleaningProfile? {
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

        func save(_ item: AdaptiveCleaningProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCleaningProfile] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCleaningProfileStore(_ inner: MemoryAdaptiveCleaningProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCleaningProfileStore {
        return CachedAdaptiveCleaningProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive cleaning profiles. Empty fields match all.
    final class AdaptiveCleaningProfileQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCleaningProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCleaningProfile]) -> [AdaptiveCleaningProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCleaningProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCleaningProfiles(_ store: any AdaptiveCleaningProfileStore, query: AdaptiveCleaningProfileQuery) -> [AdaptiveCleaningProfile] {
        return query.apply(store.list())
    }
}
