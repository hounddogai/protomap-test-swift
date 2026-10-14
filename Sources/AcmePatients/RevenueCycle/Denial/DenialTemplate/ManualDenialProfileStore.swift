import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual denial profiles by code.
    protocol ManualDenialProfileStore {
        func find(_ code: String) -> ManualDenialProfile?
        func save(_ item: ManualDenialProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDenialProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDenialProfileStore: ManualDenialProfileStore {
        var items: [String: ManualDenialProfile]
        var order: [String]

        init(items: [String: ManualDenialProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDenialProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDenialProfile) {
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

        func list() -> [ManualDenialProfile] {
            var out: [ManualDenialProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDenialProfileStore() -> any ManualDenialProfileStore {
        return MemoryManualDenialProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDenialProfileStore: ManualDenialProfileStore {
        var inner: MemoryManualDenialProfileStore
        var cache: TTLCache<ManualDenialProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDenialProfileStore, cache: TTLCache<ManualDenialProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDenialProfile? {
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

        func save(_ item: ManualDenialProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDenialProfile] {
            return inner.list()
        }
    }

    static func newCachedManualDenialProfileStore(_ inner: MemoryManualDenialProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDenialProfileStore {
        return CachedManualDenialProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual denial profiles. Empty fields match all.
    final class ManualDenialProfileQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDenialProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualDenialProfile]) -> [ManualDenialProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDenialProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDenialProfiles(_ store: any ManualDenialProfileStore, query: ManualDenialProfileQuery) -> [ManualDenialProfile] {
        return query.apply(store.list())
    }
}
