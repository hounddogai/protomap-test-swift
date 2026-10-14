import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default interaction profiles by code.
    protocol DefaultInteractionProfileStore {
        func find(_ code: String) -> DefaultInteractionProfile?
        func save(_ item: DefaultInteractionProfile)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultInteractionProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultInteractionProfileStore: DefaultInteractionProfileStore {
        var items: [String: DefaultInteractionProfile]
        var order: [String]

        init(items: [String: DefaultInteractionProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultInteractionProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultInteractionProfile) {
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

        func list() -> [DefaultInteractionProfile] {
            var out: [DefaultInteractionProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultInteractionProfileStore() -> any DefaultInteractionProfileStore {
        return MemoryDefaultInteractionProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultInteractionProfileStore: DefaultInteractionProfileStore {
        var inner: MemoryDefaultInteractionProfileStore
        var cache: TTLCache<DefaultInteractionProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultInteractionProfileStore, cache: TTLCache<DefaultInteractionProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultInteractionProfile? {
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

        func save(_ item: DefaultInteractionProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultInteractionProfile] {
            return inner.list()
        }
    }

    static func newCachedDefaultInteractionProfileStore(_ inner: MemoryDefaultInteractionProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultInteractionProfileStore {
        return CachedDefaultInteractionProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default interaction profiles. Empty fields match all.
    final class DefaultInteractionProfileQuery {
        var region: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultInteractionProfile) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultInteractionProfile]) -> [DefaultInteractionProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultInteractionProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultInteractionProfiles(_ store: any DefaultInteractionProfileStore, query: DefaultInteractionProfileQuery) -> [DefaultInteractionProfile] {
        return query.apply(store.list())
    }
}
