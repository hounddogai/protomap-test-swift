import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial ledgers by code.
    protocol DenialLedgerStore {
        func find(_ code: String) -> DenialLedger?
        func save(_ item: DenialLedger)
        func remove(_ code: String) -> Bool
        func list() -> [DenialLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialLedgerStore: DenialLedgerStore {
        var items: [String: DenialLedger]
        var order: [String]

        init(items: [String: DenialLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialLedger) {
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

        func list() -> [DenialLedger] {
            var out: [DenialLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialLedgerStore() -> any DenialLedgerStore {
        return MemoryDenialLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialLedgerStore: DenialLedgerStore {
        var inner: MemoryDenialLedgerStore
        var cache: TTLCache<DenialLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialLedgerStore, cache: TTLCache<DenialLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialLedger? {
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

        func save(_ item: DenialLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialLedger] {
            return inner.list()
        }
    }

    static func newCachedDenialLedgerStore(_ inner: MemoryDenialLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialLedgerStore {
        return CachedDenialLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial ledgers. Empty fields match all.
    final class DenialLedgerQuery {
        var ward: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRatio: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialLedger) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialLedger]) -> [DenialLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialLedgers(_ store: any DenialLedgerStore, query: DenialLedgerQuery) -> [DenialLedger] {
        return query.apply(store.list())
    }
}
