import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched cleaning overrides by code.
    protocol BatchedCleaningOverrideStore {
        func find(_ code: String) -> BatchedCleaningOverride?
        func save(_ item: BatchedCleaningOverride)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCleaningOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCleaningOverrideStore: BatchedCleaningOverrideStore {
        var items: [String: BatchedCleaningOverride]
        var order: [String]

        init(items: [String: BatchedCleaningOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCleaningOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCleaningOverride) {
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

        func list() -> [BatchedCleaningOverride] {
            var out: [BatchedCleaningOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCleaningOverrideStore() -> any BatchedCleaningOverrideStore {
        return MemoryBatchedCleaningOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCleaningOverrideStore: BatchedCleaningOverrideStore {
        var inner: MemoryBatchedCleaningOverrideStore
        var cache: TTLCache<BatchedCleaningOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCleaningOverrideStore, cache: TTLCache<BatchedCleaningOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCleaningOverride? {
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

        func save(_ item: BatchedCleaningOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCleaningOverride] {
            return inner.list()
        }
    }

    static func newCachedBatchedCleaningOverrideStore(_ inner: MemoryBatchedCleaningOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCleaningOverrideStore {
        return CachedBatchedCleaningOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched cleaning overrides. Empty fields match all.
    final class BatchedCleaningOverrideQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCleaningOverride) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [BatchedCleaningOverride]) -> [BatchedCleaningOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCleaningOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCleaningOverrides(_ store: any BatchedCleaningOverrideStore, query: BatchedCleaningOverrideQuery) -> [BatchedCleaningOverride] {
        return query.apply(store.list())
    }
}
