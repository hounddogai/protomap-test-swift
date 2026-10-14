import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched program windows by code.
    protocol BatchedProgramWindowStore {
        func find(_ code: String) -> BatchedProgramWindow?
        func save(_ item: BatchedProgramWindow)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedProgramWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedProgramWindowStore: BatchedProgramWindowStore {
        var items: [String: BatchedProgramWindow]
        var order: [String]

        init(items: [String: BatchedProgramWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedProgramWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedProgramWindow) {
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

        func list() -> [BatchedProgramWindow] {
            var out: [BatchedProgramWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedProgramWindowStore() -> any BatchedProgramWindowStore {
        return MemoryBatchedProgramWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedProgramWindowStore: BatchedProgramWindowStore {
        var inner: MemoryBatchedProgramWindowStore
        var cache: TTLCache<BatchedProgramWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedProgramWindowStore, cache: TTLCache<BatchedProgramWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedProgramWindow? {
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

        func save(_ item: BatchedProgramWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedProgramWindow] {
            return inner.list()
        }
    }

    static func newCachedBatchedProgramWindowStore(_ inner: MemoryBatchedProgramWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedProgramWindowStore {
        return CachedBatchedProgramWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched program windows. Empty fields match all.
    final class BatchedProgramWindowQuery {
        var category: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedProgramWindow) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedProgramWindow]) -> [BatchedProgramWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedProgramWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedProgramWindows(_ store: any BatchedProgramWindowStore, query: BatchedProgramWindowQuery) -> [BatchedProgramWindow] {
        return query.apply(store.list())
    }
}
