import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict inventory ledgers by code.
    protocol StrictInventoryLedgerStore {
        func find(_ code: String) -> StrictInventoryLedger?
        func save(_ item: StrictInventoryLedger)
        func remove(_ code: String) -> Bool
        func list() -> [StrictInventoryLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictInventoryLedgerStore: StrictInventoryLedgerStore {
        var items: [String: StrictInventoryLedger]
        var order: [String]

        init(items: [String: StrictInventoryLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictInventoryLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictInventoryLedger) {
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

        func list() -> [StrictInventoryLedger] {
            var out: [StrictInventoryLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictInventoryLedgerStore() -> any StrictInventoryLedgerStore {
        return MemoryStrictInventoryLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictInventoryLedgerStore: StrictInventoryLedgerStore {
        var inner: MemoryStrictInventoryLedgerStore
        var cache: TTLCache<StrictInventoryLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictInventoryLedgerStore, cache: TTLCache<StrictInventoryLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictInventoryLedger? {
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

        func save(_ item: StrictInventoryLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictInventoryLedger] {
            return inner.list()
        }
    }

    static func newCachedStrictInventoryLedgerStore(_ inner: MemoryStrictInventoryLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictInventoryLedgerStore {
        return CachedStrictInventoryLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict inventory ledgers. Empty fields match all.
    final class StrictInventoryLedgerQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictInventoryLedger) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictInventoryLedger]) -> [StrictInventoryLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictInventoryLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictInventoryLedgers(_ store: any StrictInventoryLedgerStore, query: StrictInventoryLedgerQuery) -> [StrictInventoryLedger] {
        return query.apply(store.list())
    }
}
