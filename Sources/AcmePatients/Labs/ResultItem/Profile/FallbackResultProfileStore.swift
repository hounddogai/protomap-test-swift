import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback result profiles by code.
    protocol FallbackResultProfileStore {
        func find(_ code: String) -> FallbackResultProfile?
        func save(_ item: FallbackResultProfile)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackResultProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackResultProfileStore: FallbackResultProfileStore {
        var items: [String: FallbackResultProfile]
        var order: [String]

        init(items: [String: FallbackResultProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackResultProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackResultProfile) {
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

        func list() -> [FallbackResultProfile] {
            var out: [FallbackResultProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackResultProfileStore() -> any FallbackResultProfileStore {
        return MemoryFallbackResultProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackResultProfileStore: FallbackResultProfileStore {
        var inner: MemoryFallbackResultProfileStore
        var cache: TTLCache<FallbackResultProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackResultProfileStore, cache: TTLCache<FallbackResultProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackResultProfile? {
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

        func save(_ item: FallbackResultProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackResultProfile] {
            return inner.list()
        }
    }

    static func newCachedFallbackResultProfileStore(_ inner: MemoryFallbackResultProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackResultProfileStore {
        return CachedFallbackResultProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback result profiles. Empty fields match all.
    final class FallbackResultProfileQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackResultProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackResultProfile]) -> [FallbackResultProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackResultProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackResultProfiles(_ store: any FallbackResultProfileStore, query: FallbackResultProfileQuery) -> [FallbackResultProfile] {
        return query.apply(store.list())
    }
}
