import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict authorization windows by code.
    protocol StrictAuthorizationWindowStore {
        func find(_ code: String) -> StrictAuthorizationWindow?
        func save(_ item: StrictAuthorizationWindow)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAuthorizationWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAuthorizationWindowStore: StrictAuthorizationWindowStore {
        var items: [String: StrictAuthorizationWindow]
        var order: [String]

        init(items: [String: StrictAuthorizationWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAuthorizationWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAuthorizationWindow) {
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

        func list() -> [StrictAuthorizationWindow] {
            var out: [StrictAuthorizationWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAuthorizationWindowStore() -> any StrictAuthorizationWindowStore {
        return MemoryStrictAuthorizationWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAuthorizationWindowStore: StrictAuthorizationWindowStore {
        var inner: MemoryStrictAuthorizationWindowStore
        var cache: TTLCache<StrictAuthorizationWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAuthorizationWindowStore, cache: TTLCache<StrictAuthorizationWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAuthorizationWindow? {
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

        func save(_ item: StrictAuthorizationWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAuthorizationWindow] {
            return inner.list()
        }
    }

    static func newCachedStrictAuthorizationWindowStore(_ inner: MemoryStrictAuthorizationWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAuthorizationWindowStore {
        return CachedStrictAuthorizationWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict authorization windows. Empty fields match all.
    final class StrictAuthorizationWindowQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAuthorizationWindow) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictAuthorizationWindow]) -> [StrictAuthorizationWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAuthorizationWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAuthorizationWindows(_ store: any StrictAuthorizationWindowStore, query: StrictAuthorizationWindowQuery) -> [StrictAuthorizationWindow] {
        return query.apply(store.list())
    }
}
