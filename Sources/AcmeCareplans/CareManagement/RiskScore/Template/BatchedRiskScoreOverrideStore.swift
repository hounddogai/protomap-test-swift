import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched risk score overrides by code.
    protocol BatchedRiskScoreOverrideStore {
        func find(_ code: String) -> BatchedRiskScoreOverride?
        func save(_ item: BatchedRiskScoreOverride)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRiskScoreOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRiskScoreOverrideStore: BatchedRiskScoreOverrideStore {
        var items: [String: BatchedRiskScoreOverride]
        var order: [String]

        init(items: [String: BatchedRiskScoreOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRiskScoreOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRiskScoreOverride) {
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

        func list() -> [BatchedRiskScoreOverride] {
            var out: [BatchedRiskScoreOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRiskScoreOverrideStore() -> any BatchedRiskScoreOverrideStore {
        return MemoryBatchedRiskScoreOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRiskScoreOverrideStore: BatchedRiskScoreOverrideStore {
        var inner: MemoryBatchedRiskScoreOverrideStore
        var cache: TTLCache<BatchedRiskScoreOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRiskScoreOverrideStore, cache: TTLCache<BatchedRiskScoreOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRiskScoreOverride? {
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

        func save(_ item: BatchedRiskScoreOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRiskScoreOverride] {
            return inner.list()
        }
    }

    static func newCachedBatchedRiskScoreOverrideStore(_ inner: MemoryBatchedRiskScoreOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRiskScoreOverrideStore {
        return CachedBatchedRiskScoreOverrideStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched risk score overrides. Empty fields match all.
    final class BatchedRiskScoreOverrideQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRiskScoreOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRiskScoreOverride]) -> [BatchedRiskScoreOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRiskScoreOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRiskScoreOverrides(_ store: any BatchedRiskScoreOverrideStore, query: BatchedRiskScoreOverrideQuery) -> [BatchedRiskScoreOverride] {
        return query.apply(store.list())
    }
}
