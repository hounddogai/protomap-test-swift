import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback modality entries by code.
    protocol FallbackModalityEntryStore {
        func find(_ code: String) -> FallbackModalityEntry?
        func save(_ item: FallbackModalityEntry)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackModalityEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackModalityEntryStore: FallbackModalityEntryStore {
        var items: [String: FallbackModalityEntry]
        var order: [String]

        init(items: [String: FallbackModalityEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackModalityEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackModalityEntry) {
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

        func list() -> [FallbackModalityEntry] {
            var out: [FallbackModalityEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackModalityEntryStore() -> any FallbackModalityEntryStore {
        return MemoryFallbackModalityEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackModalityEntryStore: FallbackModalityEntryStore {
        var inner: MemoryFallbackModalityEntryStore
        var cache: TTLCache<FallbackModalityEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackModalityEntryStore, cache: TTLCache<FallbackModalityEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackModalityEntry? {
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

        func save(_ item: FallbackModalityEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackModalityEntry] {
            return inner.list()
        }
    }

    static func newCachedFallbackModalityEntryStore(_ inner: MemoryFallbackModalityEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackModalityEntryStore {
        return CachedFallbackModalityEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback modality entries. Empty fields match all.
    final class FallbackModalityEntryQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackModalityEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackModalityEntry]) -> [FallbackModalityEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackModalityEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackModalityEntries(_ store: any FallbackModalityEntryStore, query: FallbackModalityEntryQuery) -> [FallbackModalityEntry] {
        return query.apply(store.list())
    }
}
