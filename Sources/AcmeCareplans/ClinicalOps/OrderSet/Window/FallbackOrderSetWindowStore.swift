import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback order set windows by code.
    protocol FallbackOrderSetWindowStore {
        func find(_ code: String) -> FallbackOrderSetWindow?
        func save(_ item: FallbackOrderSetWindow)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackOrderSetWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackOrderSetWindowStore: FallbackOrderSetWindowStore {
        var items: [String: FallbackOrderSetWindow]
        var order: [String]

        init(items: [String: FallbackOrderSetWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackOrderSetWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackOrderSetWindow) {
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

        func list() -> [FallbackOrderSetWindow] {
            var out: [FallbackOrderSetWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackOrderSetWindowStore() -> any FallbackOrderSetWindowStore {
        return MemoryFallbackOrderSetWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackOrderSetWindowStore: FallbackOrderSetWindowStore {
        var inner: MemoryFallbackOrderSetWindowStore
        var cache: TTLCache<FallbackOrderSetWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackOrderSetWindowStore, cache: TTLCache<FallbackOrderSetWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackOrderSetWindow? {
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

        func save(_ item: FallbackOrderSetWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackOrderSetWindow] {
            return inner.list()
        }
    }

    static func newCachedFallbackOrderSetWindowStore(_ inner: MemoryFallbackOrderSetWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackOrderSetWindowStore {
        return CachedFallbackOrderSetWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback order set windows. Empty fields match all.
    final class FallbackOrderSetWindowQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackOrderSetWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackOrderSetWindow]) -> [FallbackOrderSetWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackOrderSetWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackOrderSetWindows(_ store: any FallbackOrderSetWindowStore, query: FallbackOrderSetWindowQuery) -> [FallbackOrderSetWindow] {
        return query.apply(store.list())
    }
}
