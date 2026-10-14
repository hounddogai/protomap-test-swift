import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task ledgers by code.
    protocol TaskLedgerStore {
        func find(_ code: String) -> TaskLedger?
        func save(_ item: TaskLedger)
        func remove(_ code: String) -> Bool
        func list() -> [TaskLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskLedgerStore: TaskLedgerStore {
        var items: [String: TaskLedger]
        var order: [String]

        init(items: [String: TaskLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskLedger) {
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

        func list() -> [TaskLedger] {
            var out: [TaskLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskLedgerStore() -> any TaskLedgerStore {
        return MemoryTaskLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskLedgerStore: TaskLedgerStore {
        var inner: MemoryTaskLedgerStore
        var cache: TTLCache<TaskLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskLedgerStore, cache: TTLCache<TaskLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskLedger? {
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

        func save(_ item: TaskLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskLedger] {
            return inner.list()
        }
    }

    static func newCachedTaskLedgerStore(_ inner: MemoryTaskLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskLedgerStore {
        return CachedTaskLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task ledgers. Empty fields match all.
    final class TaskLedgerQuery {
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

        func matches(_ item: TaskLedger) -> Bool {
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

        func apply(_ items: [TaskLedger]) -> [TaskLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskLedgers(_ store: any TaskLedgerStore, query: TaskLedgerQuery) -> [TaskLedger] {
        return query.apply(store.list())
    }
}
