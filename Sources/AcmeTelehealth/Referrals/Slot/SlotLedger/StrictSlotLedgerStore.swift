import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict slot ledgers by code.
    protocol StrictSlotLedgerStore {
        func find(_ code: String) -> StrictSlotLedger?
        func save(_ item: StrictSlotLedger)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSlotLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSlotLedgerStore: StrictSlotLedgerStore {
        var items: [String: StrictSlotLedger]
        var order: [String]

        init(items: [String: StrictSlotLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSlotLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSlotLedger) {
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

        func list() -> [StrictSlotLedger] {
            var out: [StrictSlotLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSlotLedgerStore() -> any StrictSlotLedgerStore {
        return MemoryStrictSlotLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSlotLedgerStore: StrictSlotLedgerStore {
        var inner: MemoryStrictSlotLedgerStore
        var cache: TTLCache<StrictSlotLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSlotLedgerStore, cache: TTLCache<StrictSlotLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSlotLedger? {
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

        func save(_ item: StrictSlotLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSlotLedger] {
            return inner.list()
        }
    }

    static func newCachedStrictSlotLedgerStore(_ inner: MemoryStrictSlotLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSlotLedgerStore {
        return CachedStrictSlotLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict slot ledgers. Empty fields match all.
    final class StrictSlotLedgerQuery {
        var segment: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minRate: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSlotLedger) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSlotLedger]) -> [StrictSlotLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSlotLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSlotLedgers(_ store: any StrictSlotLedgerStore, query: StrictSlotLedgerQuery) -> [StrictSlotLedger] {
        return query.apply(store.list())
    }
}
