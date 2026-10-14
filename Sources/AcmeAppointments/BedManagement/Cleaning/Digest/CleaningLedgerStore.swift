import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning ledgers by code.
    protocol CleaningLedgerStore {
        func find(_ code: String) -> CleaningLedger?
        func save(_ item: CleaningLedger)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningLedgerStore: CleaningLedgerStore {
        var items: [String: CleaningLedger]
        var order: [String]

        init(items: [String: CleaningLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningLedger) {
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

        func list() -> [CleaningLedger] {
            var out: [CleaningLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningLedgerStore() -> any CleaningLedgerStore {
        return MemoryCleaningLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningLedgerStore: CleaningLedgerStore {
        var inner: MemoryCleaningLedgerStore
        var cache: TTLCache<CleaningLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningLedgerStore, cache: TTLCache<CleaningLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningLedger? {
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

        func save(_ item: CleaningLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningLedger] {
            return inner.list()
        }
    }

    static func newCachedCleaningLedgerStore(_ inner: MemoryCleaningLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningLedgerStore {
        return CachedCleaningLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning ledgers. Empty fields match all.
    final class CleaningLedgerQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningLedger) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningLedger]) -> [CleaningLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningLedgers(_ store: any CleaningLedgerStore, query: CleaningLedgerQuery) -> [CleaningLedger] {
        return query.apply(store.list())
    }
}
