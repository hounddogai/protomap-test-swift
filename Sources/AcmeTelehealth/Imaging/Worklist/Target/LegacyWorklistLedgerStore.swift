import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy worklist ledgers by code.
    protocol LegacyWorklistLedgerStore {
        func find(_ code: String) -> LegacyWorklistLedger?
        func save(_ item: LegacyWorklistLedger)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyWorklistLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyWorklistLedgerStore: LegacyWorklistLedgerStore {
        var items: [String: LegacyWorklistLedger]
        var order: [String]

        init(items: [String: LegacyWorklistLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyWorklistLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyWorklistLedger) {
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

        func list() -> [LegacyWorklistLedger] {
            var out: [LegacyWorklistLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyWorklistLedgerStore() -> any LegacyWorklistLedgerStore {
        return MemoryLegacyWorklistLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyWorklistLedgerStore: LegacyWorklistLedgerStore {
        var inner: MemoryLegacyWorklistLedgerStore
        var cache: TTLCache<LegacyWorklistLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyWorklistLedgerStore, cache: TTLCache<LegacyWorklistLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyWorklistLedger? {
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

        func save(_ item: LegacyWorklistLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyWorklistLedger] {
            return inner.list()
        }
    }

    static func newCachedLegacyWorklistLedgerStore(_ inner: MemoryLegacyWorklistLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyWorklistLedgerStore {
        return CachedLegacyWorklistLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy worklist ledgers. Empty fields match all.
    final class LegacyWorklistLedgerQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyWorklistLedger) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [LegacyWorklistLedger]) -> [LegacyWorklistLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyWorklistLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyWorklistLedgers(_ store: any LegacyWorklistLedgerStore, query: LegacyWorklistLedgerQuery) -> [LegacyWorklistLedger] {
        return query.apply(store.list())
    }
}
