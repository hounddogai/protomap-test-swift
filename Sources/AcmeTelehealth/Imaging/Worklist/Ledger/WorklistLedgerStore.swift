import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist ledgers by code.
    protocol WorklistLedgerStore {
        func find(_ code: String) -> WorklistLedger?
        func save(_ item: WorklistLedger)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistLedgerStore: WorklistLedgerStore {
        var items: [String: WorklistLedger]
        var order: [String]

        init(items: [String: WorklistLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistLedger) {
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

        func list() -> [WorklistLedger] {
            var out: [WorklistLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistLedgerStore() -> any WorklistLedgerStore {
        return MemoryWorklistLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistLedgerStore: WorklistLedgerStore {
        var inner: MemoryWorklistLedgerStore
        var cache: TTLCache<WorklistLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistLedgerStore, cache: TTLCache<WorklistLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistLedger? {
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

        func save(_ item: WorklistLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistLedger] {
            return inner.list()
        }
    }

    static func newCachedWorklistLedgerStore(_ inner: MemoryWorklistLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistLedgerStore {
        return CachedWorklistLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist ledgers. Empty fields match all.
    final class WorklistLedgerQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistLedger]) -> [WorklistLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistLedgers(_ store: any WorklistLedgerStore, query: WorklistLedgerQuery) -> [WorklistLedger] {
        return query.apply(store.list())
    }
}
