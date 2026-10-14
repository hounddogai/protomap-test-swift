import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched bed board ledgers by code.
    protocol BatchedBedBoardLedgerStore {
        func find(_ code: String) -> BatchedBedBoardLedger?
        func save(_ item: BatchedBedBoardLedger)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedBedBoardLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedBedBoardLedgerStore: BatchedBedBoardLedgerStore {
        var items: [String: BatchedBedBoardLedger]
        var order: [String]

        init(items: [String: BatchedBedBoardLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedBedBoardLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedBedBoardLedger) {
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

        func list() -> [BatchedBedBoardLedger] {
            var out: [BatchedBedBoardLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedBedBoardLedgerStore() -> any BatchedBedBoardLedgerStore {
        return MemoryBatchedBedBoardLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedBedBoardLedgerStore: BatchedBedBoardLedgerStore {
        var inner: MemoryBatchedBedBoardLedgerStore
        var cache: TTLCache<BatchedBedBoardLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedBedBoardLedgerStore, cache: TTLCache<BatchedBedBoardLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedBedBoardLedger? {
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

        func save(_ item: BatchedBedBoardLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedBedBoardLedger] {
            return inner.list()
        }
    }

    static func newCachedBatchedBedBoardLedgerStore(_ inner: MemoryBatchedBedBoardLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedBedBoardLedgerStore {
        return CachedBatchedBedBoardLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched bed board ledgers. Empty fields match all.
    final class BatchedBedBoardLedgerQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedBedBoardLedger) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedBedBoardLedger]) -> [BatchedBedBoardLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedBedBoardLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedBedBoardLedgers(_ store: any BatchedBedBoardLedgerStore, query: BatchedBedBoardLedgerQuery) -> [BatchedBedBoardLedger] {
        return query.apply(store.list())
    }
}
