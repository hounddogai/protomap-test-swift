import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge ledgers by code.
    protocol ChargeLedgerStore {
        func find(_ code: String) -> ChargeLedger?
        func save(_ item: ChargeLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeLedgerStore: ChargeLedgerStore {
        var items: [String: ChargeLedger]
        var order: [String]

        init(items: [String: ChargeLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeLedger) {
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

        func list() -> [ChargeLedger] {
            var out: [ChargeLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeLedgerStore() -> any ChargeLedgerStore {
        return MemoryChargeLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeLedgerStore: ChargeLedgerStore {
        var inner: MemoryChargeLedgerStore
        var cache: TTLCache<ChargeLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeLedgerStore, cache: TTLCache<ChargeLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeLedger? {
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

        func save(_ item: ChargeLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeLedger] {
            return inner.list()
        }
    }

    static func newCachedChargeLedgerStore(_ inner: MemoryChargeLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeLedgerStore {
        return CachedChargeLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge ledgers. Empty fields match all.
    final class ChargeLedgerQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeLedger) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeLedger]) -> [ChargeLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeLedgers(_ store: any ChargeLedgerStore, query: ChargeLedgerQuery) -> [ChargeLedger] {
        return query.apply(store.list())
    }
}
