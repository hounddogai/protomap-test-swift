import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer windows by code.
    protocol TransferWindowStore {
        func find(_ code: String) -> TransferWindow?
        func save(_ item: TransferWindow)
        func remove(_ code: String) -> Bool
        func list() -> [TransferWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferWindowStore: TransferWindowStore {
        var items: [String: TransferWindow]
        var order: [String]

        init(items: [String: TransferWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferWindow) {
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

        func list() -> [TransferWindow] {
            var out: [TransferWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferWindowStore() -> any TransferWindowStore {
        return MemoryTransferWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferWindowStore: TransferWindowStore {
        var inner: MemoryTransferWindowStore
        var cache: TTLCache<TransferWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferWindowStore, cache: TTLCache<TransferWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferWindow? {
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

        func save(_ item: TransferWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferWindow] {
            return inner.list()
        }
    }

    static func newCachedTransferWindowStore(_ inner: MemoryTransferWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferWindowStore {
        return CachedTransferWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer windows. Empty fields match all.
    final class TransferWindowQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [TransferWindow]) -> [TransferWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferWindows(_ store: any TransferWindowStore, query: TransferWindowQuery) -> [TransferWindow] {
        return query.apply(store.list())
    }
}
