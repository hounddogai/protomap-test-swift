import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual census ledgers by code.
    protocol ManualCensusLedgerStore {
        func find(_ code: String) -> ManualCensusLedger?
        func save(_ item: ManualCensusLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCensusLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCensusLedgerStore: ManualCensusLedgerStore {
        var items: [String: ManualCensusLedger]
        var order: [String]

        init(items: [String: ManualCensusLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCensusLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCensusLedger) {
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

        func list() -> [ManualCensusLedger] {
            var out: [ManualCensusLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCensusLedgerStore() -> any ManualCensusLedgerStore {
        return MemoryManualCensusLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCensusLedgerStore: ManualCensusLedgerStore {
        var inner: MemoryManualCensusLedgerStore
        var cache: TTLCache<ManualCensusLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCensusLedgerStore, cache: TTLCache<ManualCensusLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCensusLedger? {
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

        func save(_ item: ManualCensusLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCensusLedger] {
            return inner.list()
        }
    }

    static func newCachedManualCensusLedgerStore(_ inner: MemoryManualCensusLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCensusLedgerStore {
        return CachedManualCensusLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual census ledgers. Empty fields match all.
    final class ManualCensusLedgerQuery {
        var locale: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRefills: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCensusLedger) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCensusLedger]) -> [ManualCensusLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCensusLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCensusLedgers(_ store: any ManualCensusLedgerStore, query: ManualCensusLedgerQuery) -> [ManualCensusLedger] {
        return query.apply(store.list())
    }
}
