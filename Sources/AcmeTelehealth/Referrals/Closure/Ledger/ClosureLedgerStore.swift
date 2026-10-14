import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure ledgers by code.
    protocol ClosureLedgerStore {
        func find(_ code: String) -> ClosureLedger?
        func save(_ item: ClosureLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureLedgerStore: ClosureLedgerStore {
        var items: [String: ClosureLedger]
        var order: [String]

        init(items: [String: ClosureLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureLedger) {
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

        func list() -> [ClosureLedger] {
            var out: [ClosureLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureLedgerStore() -> any ClosureLedgerStore {
        return MemoryClosureLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureLedgerStore: ClosureLedgerStore {
        var inner: MemoryClosureLedgerStore
        var cache: TTLCache<ClosureLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureLedgerStore, cache: TTLCache<ClosureLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureLedger? {
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

        func save(_ item: ClosureLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureLedger] {
            return inner.list()
        }
    }

    static func newCachedClosureLedgerStore(_ inner: MemoryClosureLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureLedgerStore {
        return CachedClosureLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure ledgers. Empty fields match all.
    final class ClosureLedgerQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ClosureLedger]) -> [ClosureLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureLedgers(_ store: any ClosureLedgerStore, query: ClosureLedgerQuery) -> [ClosureLedger] {
        return query.apply(store.list())
    }
}
