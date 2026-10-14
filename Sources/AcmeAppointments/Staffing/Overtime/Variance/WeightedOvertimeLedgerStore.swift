import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted overtime ledgers by code.
    protocol WeightedOvertimeLedgerStore {
        func find(_ code: String) -> WeightedOvertimeLedger?
        func save(_ item: WeightedOvertimeLedger)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedOvertimeLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedOvertimeLedgerStore: WeightedOvertimeLedgerStore {
        var items: [String: WeightedOvertimeLedger]
        var order: [String]

        init(items: [String: WeightedOvertimeLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedOvertimeLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedOvertimeLedger) {
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

        func list() -> [WeightedOvertimeLedger] {
            var out: [WeightedOvertimeLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedOvertimeLedgerStore() -> any WeightedOvertimeLedgerStore {
        return MemoryWeightedOvertimeLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedOvertimeLedgerStore: WeightedOvertimeLedgerStore {
        var inner: MemoryWeightedOvertimeLedgerStore
        var cache: TTLCache<WeightedOvertimeLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedOvertimeLedgerStore, cache: TTLCache<WeightedOvertimeLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedOvertimeLedger? {
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

        func save(_ item: WeightedOvertimeLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedOvertimeLedger] {
            return inner.list()
        }
    }

    static func newCachedWeightedOvertimeLedgerStore(_ inner: MemoryWeightedOvertimeLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedOvertimeLedgerStore {
        return CachedWeightedOvertimeLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted overtime ledgers. Empty fields match all.
    final class WeightedOvertimeLedgerQuery {
        var category: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedOvertimeLedger) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedOvertimeLedger]) -> [WeightedOvertimeLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedOvertimeLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedOvertimeLedgers(_ store: any WeightedOvertimeLedgerStore, query: WeightedOvertimeLedgerQuery) -> [WeightedOvertimeLedger] {
        return query.apply(store.list())
    }
}
