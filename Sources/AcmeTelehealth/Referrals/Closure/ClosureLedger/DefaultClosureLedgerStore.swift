import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default closure ledgers by code.
    protocol DefaultClosureLedgerStore {
        func find(_ code: String) -> DefaultClosureLedger?
        func save(_ item: DefaultClosureLedger)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultClosureLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultClosureLedgerStore: DefaultClosureLedgerStore {
        var items: [String: DefaultClosureLedger]
        var order: [String]

        init(items: [String: DefaultClosureLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultClosureLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultClosureLedger) {
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

        func list() -> [DefaultClosureLedger] {
            var out: [DefaultClosureLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultClosureLedgerStore() -> any DefaultClosureLedgerStore {
        return MemoryDefaultClosureLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultClosureLedgerStore: DefaultClosureLedgerStore {
        var inner: MemoryDefaultClosureLedgerStore
        var cache: TTLCache<DefaultClosureLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultClosureLedgerStore, cache: TTLCache<DefaultClosureLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultClosureLedger? {
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

        func save(_ item: DefaultClosureLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultClosureLedger] {
            return inner.list()
        }
    }

    static func newCachedDefaultClosureLedgerStore(_ inner: MemoryDefaultClosureLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultClosureLedgerStore {
        return CachedDefaultClosureLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default closure ledgers. Empty fields match all.
    final class DefaultClosureLedgerQuery {
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

        func matches(_ item: DefaultClosureLedger) -> Bool {
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

        func apply(_ items: [DefaultClosureLedger]) -> [DefaultClosureLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultClosureLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultClosureLedgers(_ store: any DefaultClosureLedgerStore, query: DefaultClosureLedgerQuery) -> [DefaultClosureLedger] {
        return query.apply(store.list())
    }
}
