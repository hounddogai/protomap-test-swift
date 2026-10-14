import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback task entries by code.
    protocol FallbackTaskEntryStore {
        func find(_ code: String) -> FallbackTaskEntry?
        func save(_ item: FallbackTaskEntry)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackTaskEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackTaskEntryStore: FallbackTaskEntryStore {
        var items: [String: FallbackTaskEntry]
        var order: [String]

        init(items: [String: FallbackTaskEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackTaskEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackTaskEntry) {
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

        func list() -> [FallbackTaskEntry] {
            var out: [FallbackTaskEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackTaskEntryStore() -> any FallbackTaskEntryStore {
        return MemoryFallbackTaskEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackTaskEntryStore: FallbackTaskEntryStore {
        var inner: MemoryFallbackTaskEntryStore
        var cache: TTLCache<FallbackTaskEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackTaskEntryStore, cache: TTLCache<FallbackTaskEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackTaskEntry? {
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

        func save(_ item: FallbackTaskEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackTaskEntry] {
            return inner.list()
        }
    }

    static func newCachedFallbackTaskEntryStore(_ inner: MemoryFallbackTaskEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackTaskEntryStore {
        return CachedFallbackTaskEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback task entries. Empty fields match all.
    final class FallbackTaskEntryQuery {
        var category: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRatio: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackTaskEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackTaskEntry]) -> [FallbackTaskEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackTaskEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackTaskEntries(_ store: any FallbackTaskEntryStore, query: FallbackTaskEntryQuery) -> [FallbackTaskEntry] {
        return query.apply(store.list())
    }
}
