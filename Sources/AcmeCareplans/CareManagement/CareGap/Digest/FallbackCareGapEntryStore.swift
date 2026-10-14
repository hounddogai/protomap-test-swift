import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback care gap entries by code.
    protocol FallbackCareGapEntryStore {
        func find(_ code: String) -> FallbackCareGapEntry?
        func save(_ item: FallbackCareGapEntry)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareGapEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareGapEntryStore: FallbackCareGapEntryStore {
        var items: [String: FallbackCareGapEntry]
        var order: [String]

        init(items: [String: FallbackCareGapEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareGapEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareGapEntry) {
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

        func list() -> [FallbackCareGapEntry] {
            var out: [FallbackCareGapEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareGapEntryStore() -> any FallbackCareGapEntryStore {
        return MemoryFallbackCareGapEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareGapEntryStore: FallbackCareGapEntryStore {
        var inner: MemoryFallbackCareGapEntryStore
        var cache: TTLCache<FallbackCareGapEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareGapEntryStore, cache: TTLCache<FallbackCareGapEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareGapEntry? {
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

        func save(_ item: FallbackCareGapEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareGapEntry] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareGapEntryStore(_ inner: MemoryFallbackCareGapEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareGapEntryStore {
        return CachedFallbackCareGapEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care gap entries. Empty fields match all.
    final class FallbackCareGapEntryQuery {
        var category: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareGapEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCareGapEntry]) -> [FallbackCareGapEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareGapEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareGapEntries(_ store: any FallbackCareGapEntryStore, query: FallbackCareGapEntryQuery) -> [FallbackCareGapEntry] {
        return query.apply(store.list())
    }
}
