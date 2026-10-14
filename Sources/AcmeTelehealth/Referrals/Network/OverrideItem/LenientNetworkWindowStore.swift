import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient network windows by code.
    protocol LenientNetworkWindowStore {
        func find(_ code: String) -> LenientNetworkWindow?
        func save(_ item: LenientNetworkWindow)
        func remove(_ code: String) -> Bool
        func list() -> [LenientNetworkWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientNetworkWindowStore: LenientNetworkWindowStore {
        var items: [String: LenientNetworkWindow]
        var order: [String]

        init(items: [String: LenientNetworkWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientNetworkWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientNetworkWindow) {
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

        func list() -> [LenientNetworkWindow] {
            var out: [LenientNetworkWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientNetworkWindowStore() -> any LenientNetworkWindowStore {
        return MemoryLenientNetworkWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientNetworkWindowStore: LenientNetworkWindowStore {
        var inner: MemoryLenientNetworkWindowStore
        var cache: TTLCache<LenientNetworkWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientNetworkWindowStore, cache: TTLCache<LenientNetworkWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientNetworkWindow? {
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

        func save(_ item: LenientNetworkWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientNetworkWindow] {
            return inner.list()
        }
    }

    static func newCachedLenientNetworkWindowStore(_ inner: MemoryLenientNetworkWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientNetworkWindowStore {
        return CachedLenientNetworkWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient network windows. Empty fields match all.
    final class LenientNetworkWindowQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientNetworkWindow) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientNetworkWindow]) -> [LenientNetworkWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientNetworkWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientNetworkWindows(_ store: any LenientNetworkWindowStore, query: LenientNetworkWindowQuery) -> [LenientNetworkWindow] {
        return query.apply(store.list())
    }
}
