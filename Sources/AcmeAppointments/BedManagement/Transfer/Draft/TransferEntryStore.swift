import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer entries by code.
    protocol TransferEntryStore {
        func find(_ code: String) -> TransferEntry?
        func save(_ item: TransferEntry)
        func remove(_ code: String) -> Bool
        func list() -> [TransferEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferEntryStore: TransferEntryStore {
        var items: [String: TransferEntry]
        var order: [String]

        init(items: [String: TransferEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferEntry) {
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

        func list() -> [TransferEntry] {
            var out: [TransferEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferEntryStore() -> any TransferEntryStore {
        return MemoryTransferEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferEntryStore: TransferEntryStore {
        var inner: MemoryTransferEntryStore
        var cache: TTLCache<TransferEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferEntryStore, cache: TTLCache<TransferEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferEntry? {
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

        func save(_ item: TransferEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferEntry] {
            return inner.list()
        }
    }

    static func newCachedTransferEntryStore(_ inner: MemoryTransferEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferEntryStore {
        return CachedTransferEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer entries. Empty fields match all.
    final class TransferEntryQuery {
        var channel: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVersion: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferEntry) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferEntry]) -> [TransferEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferEntries(_ store: any TransferEntryStore, query: TransferEntryQuery) -> [TransferEntry] {
        return query.apply(store.list())
    }
}
