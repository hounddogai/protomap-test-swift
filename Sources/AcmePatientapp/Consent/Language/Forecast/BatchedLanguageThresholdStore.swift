import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched language thresholds by code.
    protocol BatchedLanguageThresholdStore {
        func find(_ code: String) -> BatchedLanguageThreshold?
        func save(_ item: BatchedLanguageThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedLanguageThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedLanguageThresholdStore: BatchedLanguageThresholdStore {
        var items: [String: BatchedLanguageThreshold]
        var order: [String]

        init(items: [String: BatchedLanguageThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedLanguageThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedLanguageThreshold) {
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

        func list() -> [BatchedLanguageThreshold] {
            var out: [BatchedLanguageThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedLanguageThresholdStore() -> any BatchedLanguageThresholdStore {
        return MemoryBatchedLanguageThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedLanguageThresholdStore: BatchedLanguageThresholdStore {
        var inner: MemoryBatchedLanguageThresholdStore
        var cache: TTLCache<BatchedLanguageThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedLanguageThresholdStore, cache: TTLCache<BatchedLanguageThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedLanguageThreshold? {
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

        func save(_ item: BatchedLanguageThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedLanguageThreshold] {
            return inner.list()
        }
    }

    static func newCachedBatchedLanguageThresholdStore(_ inner: MemoryBatchedLanguageThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedLanguageThresholdStore {
        return CachedBatchedLanguageThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched language thresholds. Empty fields match all.
    final class BatchedLanguageThresholdQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedLanguageThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedLanguageThreshold]) -> [BatchedLanguageThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedLanguageThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedLanguageThresholds(_ store: any BatchedLanguageThresholdStore, query: BatchedLanguageThresholdQuery) -> [BatchedLanguageThreshold] {
        return query.apply(store.list())
    }
}
