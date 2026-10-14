import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation profiles by code.
    protocol IsolationProfileStore {
        func find(_ code: String) -> IsolationProfile?
        func save(_ item: IsolationProfile)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationProfileStore: IsolationProfileStore {
        var items: [String: IsolationProfile]
        var order: [String]

        init(items: [String: IsolationProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationProfile) {
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

        func list() -> [IsolationProfile] {
            var out: [IsolationProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationProfileStore() -> any IsolationProfileStore {
        return MemoryIsolationProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationProfileStore: IsolationProfileStore {
        var inner: MemoryIsolationProfileStore
        var cache: TTLCache<IsolationProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationProfileStore, cache: TTLCache<IsolationProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationProfile? {
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

        func save(_ item: IsolationProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationProfile] {
            return inner.list()
        }
    }

    static func newCachedIsolationProfileStore(_ inner: MemoryIsolationProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationProfileStore {
        return CachedIsolationProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation profiles. Empty fields match all.
    final class IsolationProfileQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [IsolationProfile]) -> [IsolationProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationProfiles(_ store: any IsolationProfileStore, query: IsolationProfileQuery) -> [IsolationProfile] {
        return query.apply(store.list())
    }
}
