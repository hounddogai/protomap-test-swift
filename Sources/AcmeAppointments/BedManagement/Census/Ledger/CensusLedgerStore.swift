import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census ledgers by code.
    protocol CensusLedgerStore {
        func find(_ code: String) -> CensusLedger?
        func save(_ item: CensusLedger)
        func remove(_ code: String) -> Bool
        func list() -> [CensusLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusLedgerStore: CensusLedgerStore {
        var items: [String: CensusLedger]
        var order: [String]

        init(items: [String: CensusLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusLedger) {
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

        func list() -> [CensusLedger] {
            var out: [CensusLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusLedgerStore() -> any CensusLedgerStore {
        return MemoryCensusLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusLedgerStore: CensusLedgerStore {
        var inner: MemoryCensusLedgerStore
        var cache: TTLCache<CensusLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusLedgerStore, cache: TTLCache<CensusLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusLedger? {
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

        func save(_ item: CensusLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusLedger] {
            return inner.list()
        }
    }

    static func newCachedCensusLedgerStore(_ inner: MemoryCensusLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusLedgerStore {
        return CachedCensusLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census ledgers. Empty fields match all.
    final class CensusLedgerQuery {
        var channel: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusLedger]) -> [CensusLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusLedgers(_ store: any CensusLedgerStore, query: CensusLedgerQuery) -> [CensusLedger] {
        return query.apply(store.list())
    }
}
