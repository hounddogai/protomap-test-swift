import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer records by code.
    protocol TransferRecordStore {
        func find(_ code: String) -> TransferRecord?
        func save(_ item: TransferRecord)
        func remove(_ code: String) -> Bool
        func list() -> [TransferRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferRecordStore: TransferRecordStore {
        var items: [String: TransferRecord]
        var order: [String]

        init(items: [String: TransferRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferRecord) {
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

        func list() -> [TransferRecord] {
            var out: [TransferRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferRecordStore() -> any TransferRecordStore {
        return MemoryTransferRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferRecordStore: TransferRecordStore {
        var inner: MemoryTransferRecordStore
        var cache: TTLCache<TransferRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferRecordStore, cache: TTLCache<TransferRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferRecord? {
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

        func save(_ item: TransferRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferRecord] {
            return inner.list()
        }
    }

    static func newCachedTransferRecordStore(_ inner: MemoryTransferRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferRecordStore {
        return CachedTransferRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer records. Empty fields match all.
    final class TransferRecordQuery {
        var category: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferRecord) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [TransferRecord]) -> [TransferRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferRecords(_ store: any TransferRecordStore, query: TransferRecordQuery) -> [TransferRecord] {
        return query.apply(store.list())
    }
}
