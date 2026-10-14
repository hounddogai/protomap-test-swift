import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback care protocol windows by code.
    protocol FallbackCareProtocolWindowStore {
        func find(_ code: String) -> FallbackCareProtocolWindow?
        func save(_ item: FallbackCareProtocolWindow)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareProtocolWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareProtocolWindowStore: FallbackCareProtocolWindowStore {
        var items: [String: FallbackCareProtocolWindow]
        var order: [String]

        init(items: [String: FallbackCareProtocolWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareProtocolWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareProtocolWindow) {
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

        func list() -> [FallbackCareProtocolWindow] {
            var out: [FallbackCareProtocolWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareProtocolWindowStore() -> any FallbackCareProtocolWindowStore {
        return MemoryFallbackCareProtocolWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareProtocolWindowStore: FallbackCareProtocolWindowStore {
        var inner: MemoryFallbackCareProtocolWindowStore
        var cache: TTLCache<FallbackCareProtocolWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareProtocolWindowStore, cache: TTLCache<FallbackCareProtocolWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareProtocolWindow? {
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

        func save(_ item: FallbackCareProtocolWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareProtocolWindow] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareProtocolWindowStore(_ inner: MemoryFallbackCareProtocolWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareProtocolWindowStore {
        return CachedFallbackCareProtocolWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care protocol windows. Empty fields match all.
    final class FallbackCareProtocolWindowQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareProtocolWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCareProtocolWindow]) -> [FallbackCareProtocolWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareProtocolWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareProtocolWindows(_ store: any FallbackCareProtocolWindowStore, query: FallbackCareProtocolWindowQuery) -> [FallbackCareProtocolWindow] {
        return query.apply(store.list())
    }
}
