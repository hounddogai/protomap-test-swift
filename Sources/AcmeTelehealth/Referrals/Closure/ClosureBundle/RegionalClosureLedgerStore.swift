import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional closure ledgers by code.
    protocol RegionalClosureLedgerStore {
        func find(_ code: String) -> RegionalClosureLedger?
        func save(_ item: RegionalClosureLedger)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalClosureLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalClosureLedgerStore: RegionalClosureLedgerStore {
        var items: [String: RegionalClosureLedger]
        var order: [String]

        init(items: [String: RegionalClosureLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalClosureLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalClosureLedger) {
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

        func list() -> [RegionalClosureLedger] {
            var out: [RegionalClosureLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalClosureLedgerStore() -> any RegionalClosureLedgerStore {
        return MemoryRegionalClosureLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalClosureLedgerStore: RegionalClosureLedgerStore {
        var inner: MemoryRegionalClosureLedgerStore
        var cache: TTLCache<RegionalClosureLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalClosureLedgerStore, cache: TTLCache<RegionalClosureLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalClosureLedger? {
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

        func save(_ item: RegionalClosureLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalClosureLedger] {
            return inner.list()
        }
    }

    static func newCachedRegionalClosureLedgerStore(_ inner: MemoryRegionalClosureLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalClosureLedgerStore {
        return CachedRegionalClosureLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional closure ledgers. Empty fields match all.
    final class RegionalClosureLedgerQuery {
        var region: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCost: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalClosureLedger) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalClosureLedger]) -> [RegionalClosureLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalClosureLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalClosureLedgers(_ store: any RegionalClosureLedgerStore, query: RegionalClosureLedgerQuery) -> [RegionalClosureLedger] {
        return query.apply(store.list())
    }
}
