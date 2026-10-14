import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result ledgers by code.
    protocol ResultLedgerStore {
        func find(_ code: String) -> ResultLedger?
        func save(_ item: ResultLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ResultLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultLedgerStore: ResultLedgerStore {
        var items: [String: ResultLedger]
        var order: [String]

        init(items: [String: ResultLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultLedger) {
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

        func list() -> [ResultLedger] {
            var out: [ResultLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultLedgerStore() -> any ResultLedgerStore {
        return MemoryResultLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultLedgerStore: ResultLedgerStore {
        var inner: MemoryResultLedgerStore
        var cache: TTLCache<ResultLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultLedgerStore, cache: TTLCache<ResultLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultLedger? {
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

        func save(_ item: ResultLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultLedger] {
            return inner.list()
        }
    }

    static func newCachedResultLedgerStore(_ inner: MemoryResultLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultLedgerStore {
        return CachedResultLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result ledgers. Empty fields match all.
    final class ResultLedgerQuery {
        var channel: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minAmount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ResultLedger]) -> [ResultLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultLedgers(_ store: any ResultLedgerStore, query: ResultLedgerQuery) -> [ResultLedger] {
        return query.apply(store.list())
    }
}
