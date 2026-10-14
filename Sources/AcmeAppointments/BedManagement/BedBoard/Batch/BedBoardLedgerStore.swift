import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board ledgers by code.
    protocol BedBoardLedgerStore {
        func find(_ code: String) -> BedBoardLedger?
        func save(_ item: BedBoardLedger)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardLedgerStore: BedBoardLedgerStore {
        var items: [String: BedBoardLedger]
        var order: [String]

        init(items: [String: BedBoardLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardLedger) {
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

        func list() -> [BedBoardLedger] {
            var out: [BedBoardLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardLedgerStore() -> any BedBoardLedgerStore {
        return MemoryBedBoardLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardLedgerStore: BedBoardLedgerStore {
        var inner: MemoryBedBoardLedgerStore
        var cache: TTLCache<BedBoardLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardLedgerStore, cache: TTLCache<BedBoardLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardLedger? {
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

        func save(_ item: BedBoardLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardLedger] {
            return inner.list()
        }
    }

    static func newCachedBedBoardLedgerStore(_ inner: MemoryBedBoardLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardLedgerStore {
        return CachedBedBoardLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board ledgers. Empty fields match all.
    final class BedBoardLedgerQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardLedger]) -> [BedBoardLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardLedgers(_ store: any BedBoardLedgerStore, query: BedBoardLedgerQuery) -> [BedBoardLedger] {
        return query.apply(store.list())
    }
}
