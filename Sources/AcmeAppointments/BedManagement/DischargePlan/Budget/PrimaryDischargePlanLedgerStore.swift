import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary discharge plan ledgers by code.
    protocol PrimaryDischargePlanLedgerStore {
        func find(_ code: String) -> PrimaryDischargePlanLedger?
        func save(_ item: PrimaryDischargePlanLedger)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryDischargePlanLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryDischargePlanLedgerStore: PrimaryDischargePlanLedgerStore {
        var items: [String: PrimaryDischargePlanLedger]
        var order: [String]

        init(items: [String: PrimaryDischargePlanLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryDischargePlanLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryDischargePlanLedger) {
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

        func list() -> [PrimaryDischargePlanLedger] {
            var out: [PrimaryDischargePlanLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryDischargePlanLedgerStore() -> any PrimaryDischargePlanLedgerStore {
        return MemoryPrimaryDischargePlanLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryDischargePlanLedgerStore: PrimaryDischargePlanLedgerStore {
        var inner: MemoryPrimaryDischargePlanLedgerStore
        var cache: TTLCache<PrimaryDischargePlanLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryDischargePlanLedgerStore, cache: TTLCache<PrimaryDischargePlanLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryDischargePlanLedger? {
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

        func save(_ item: PrimaryDischargePlanLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryDischargePlanLedger] {
            return inner.list()
        }
    }

    static func newCachedPrimaryDischargePlanLedgerStore(_ inner: MemoryPrimaryDischargePlanLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryDischargePlanLedgerStore {
        return CachedPrimaryDischargePlanLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary discharge plan ledgers. Empty fields match all.
    final class PrimaryDischargePlanLedgerQuery {
        var ward: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCopay: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryDischargePlanLedger) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryDischargePlanLedger]) -> [PrimaryDischargePlanLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryDischargePlanLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryDischargePlanLedgers(_ store: any PrimaryDischargePlanLedgerStore, query: PrimaryDischargePlanLedgerQuery) -> [PrimaryDischargePlanLedger] {
        return query.apply(store.list())
    }
}
