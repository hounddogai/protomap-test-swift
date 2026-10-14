import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched authorization entries by code.
    protocol BatchedAuthorizationEntryStore {
        func find(_ code: String) -> BatchedAuthorizationEntry?
        func save(_ item: BatchedAuthorizationEntry)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAuthorizationEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAuthorizationEntryStore: BatchedAuthorizationEntryStore {
        var items: [String: BatchedAuthorizationEntry]
        var order: [String]

        init(items: [String: BatchedAuthorizationEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAuthorizationEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAuthorizationEntry) {
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

        func list() -> [BatchedAuthorizationEntry] {
            var out: [BatchedAuthorizationEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAuthorizationEntryStore() -> any BatchedAuthorizationEntryStore {
        return MemoryBatchedAuthorizationEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAuthorizationEntryStore: BatchedAuthorizationEntryStore {
        var inner: MemoryBatchedAuthorizationEntryStore
        var cache: TTLCache<BatchedAuthorizationEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAuthorizationEntryStore, cache: TTLCache<BatchedAuthorizationEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAuthorizationEntry? {
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

        func save(_ item: BatchedAuthorizationEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAuthorizationEntry] {
            return inner.list()
        }
    }

    static func newCachedBatchedAuthorizationEntryStore(_ inner: MemoryBatchedAuthorizationEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAuthorizationEntryStore {
        return CachedBatchedAuthorizationEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched authorization entries. Empty fields match all.
    final class BatchedAuthorizationEntryQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAuthorizationEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedAuthorizationEntry]) -> [BatchedAuthorizationEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAuthorizationEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAuthorizationEntries(_ store: any BatchedAuthorizationEntryStore, query: BatchedAuthorizationEntryQuery) -> [BatchedAuthorizationEntry] {
        return query.apply(store.list())
    }
}
