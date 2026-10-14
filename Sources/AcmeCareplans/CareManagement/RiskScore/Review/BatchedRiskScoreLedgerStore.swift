import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched risk score ledgers by code.
    protocol BatchedRiskScoreLedgerStore {
        func find(_ code: String) -> BatchedRiskScoreLedger?
        func save(_ item: BatchedRiskScoreLedger)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRiskScoreLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRiskScoreLedgerStore: BatchedRiskScoreLedgerStore {
        var items: [String: BatchedRiskScoreLedger]
        var order: [String]

        init(items: [String: BatchedRiskScoreLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRiskScoreLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRiskScoreLedger) {
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

        func list() -> [BatchedRiskScoreLedger] {
            var out: [BatchedRiskScoreLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRiskScoreLedgerStore() -> any BatchedRiskScoreLedgerStore {
        return MemoryBatchedRiskScoreLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRiskScoreLedgerStore: BatchedRiskScoreLedgerStore {
        var inner: MemoryBatchedRiskScoreLedgerStore
        var cache: TTLCache<BatchedRiskScoreLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRiskScoreLedgerStore, cache: TTLCache<BatchedRiskScoreLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRiskScoreLedger? {
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

        func save(_ item: BatchedRiskScoreLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRiskScoreLedger] {
            return inner.list()
        }
    }

    static func newCachedBatchedRiskScoreLedgerStore(_ inner: MemoryBatchedRiskScoreLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRiskScoreLedgerStore {
        return CachedBatchedRiskScoreLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched risk score ledgers. Empty fields match all.
    final class BatchedRiskScoreLedgerQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRiskScoreLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRiskScoreLedger]) -> [BatchedRiskScoreLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRiskScoreLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRiskScoreLedgers(_ store: any BatchedRiskScoreLedgerStore, query: BatchedRiskScoreLedgerQuery) -> [BatchedRiskScoreLedger] {
        return query.apply(store.list())
    }
}
