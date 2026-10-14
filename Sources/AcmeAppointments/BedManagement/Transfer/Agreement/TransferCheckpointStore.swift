import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer checkpoints by code.
    protocol TransferCheckpointStore {
        func find(_ code: String) -> TransferCheckpoint?
        func save(_ item: TransferCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [TransferCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferCheckpointStore: TransferCheckpointStore {
        var items: [String: TransferCheckpoint]
        var order: [String]

        init(items: [String: TransferCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferCheckpoint) {
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

        func list() -> [TransferCheckpoint] {
            var out: [TransferCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferCheckpointStore() -> any TransferCheckpointStore {
        return MemoryTransferCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferCheckpointStore: TransferCheckpointStore {
        var inner: MemoryTransferCheckpointStore
        var cache: TTLCache<TransferCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferCheckpointStore, cache: TTLCache<TransferCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferCheckpoint? {
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

        func save(_ item: TransferCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedTransferCheckpointStore(_ inner: MemoryTransferCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferCheckpointStore {
        return CachedTransferCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer checkpoints. Empty fields match all.
    final class TransferCheckpointQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferCheckpoint) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferCheckpoint]) -> [TransferCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferCheckpoints(_ store: any TransferCheckpointStore, query: TransferCheckpointQuery) -> [TransferCheckpoint] {
        return query.apply(store.list())
    }
}
