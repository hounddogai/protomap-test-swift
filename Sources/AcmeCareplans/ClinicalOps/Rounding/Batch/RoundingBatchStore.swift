import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding batches by code.
    protocol RoundingBatchStore {
        func find(_ code: String) -> RoundingBatch?
        func save(_ item: RoundingBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingBatchStore: RoundingBatchStore {
        var items: [String: RoundingBatch]
        var order: [String]

        init(items: [String: RoundingBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingBatch) {
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

        func list() -> [RoundingBatch] {
            var out: [RoundingBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingBatchStore() -> any RoundingBatchStore {
        return MemoryRoundingBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingBatchStore: RoundingBatchStore {
        var inner: MemoryRoundingBatchStore
        var cache: TTLCache<RoundingBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingBatchStore, cache: TTLCache<RoundingBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingBatch? {
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

        func save(_ item: RoundingBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingBatch] {
            return inner.list()
        }
    }

    static func newCachedRoundingBatchStore(_ inner: MemoryRoundingBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingBatchStore {
        return CachedRoundingBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding batches. Empty fields match all.
    final class RoundingBatchQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingBatch]) -> [RoundingBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingBatches(_ store: any RoundingBatchStore, query: RoundingBatchQuery) -> [RoundingBatch] {
        return query.apply(store.list())
    }
}
