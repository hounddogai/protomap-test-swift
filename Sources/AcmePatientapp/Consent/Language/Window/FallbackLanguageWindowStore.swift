import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback language windows by code.
    protocol FallbackLanguageWindowStore {
        func find(_ code: String) -> FallbackLanguageWindow?
        func save(_ item: FallbackLanguageWindow)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackLanguageWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackLanguageWindowStore: FallbackLanguageWindowStore {
        var items: [String: FallbackLanguageWindow]
        var order: [String]

        init(items: [String: FallbackLanguageWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackLanguageWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackLanguageWindow) {
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

        func list() -> [FallbackLanguageWindow] {
            var out: [FallbackLanguageWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackLanguageWindowStore() -> any FallbackLanguageWindowStore {
        return MemoryFallbackLanguageWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackLanguageWindowStore: FallbackLanguageWindowStore {
        var inner: MemoryFallbackLanguageWindowStore
        var cache: TTLCache<FallbackLanguageWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackLanguageWindowStore, cache: TTLCache<FallbackLanguageWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackLanguageWindow? {
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

        func save(_ item: FallbackLanguageWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackLanguageWindow] {
            return inner.list()
        }
    }

    static func newCachedFallbackLanguageWindowStore(_ inner: MemoryFallbackLanguageWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackLanguageWindowStore {
        return CachedFallbackLanguageWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback language windows. Empty fields match all.
    final class FallbackLanguageWindowQuery {
        var ward: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRate: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackLanguageWindow) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [FallbackLanguageWindow]) -> [FallbackLanguageWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackLanguageWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackLanguageWindows(_ store: any FallbackLanguageWindowStore, query: FallbackLanguageWindowQuery) -> [FallbackLanguageWindow] {
        return query.apply(store.list())
    }
}
