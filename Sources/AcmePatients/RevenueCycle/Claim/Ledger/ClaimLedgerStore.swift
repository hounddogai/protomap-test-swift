import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim ledgers by code.
    protocol ClaimLedgerStore {
        func find(_ code: String) -> ClaimLedger?
        func save(_ item: ClaimLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimLedgerStore: ClaimLedgerStore {
        var items: [String: ClaimLedger]
        var order: [String]

        init(items: [String: ClaimLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimLedger) {
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

        func list() -> [ClaimLedger] {
            var out: [ClaimLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimLedgerStore() -> any ClaimLedgerStore {
        return MemoryClaimLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimLedgerStore: ClaimLedgerStore {
        var inner: MemoryClaimLedgerStore
        var cache: TTLCache<ClaimLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimLedgerStore, cache: TTLCache<ClaimLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimLedger? {
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

        func save(_ item: ClaimLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimLedger] {
            return inner.list()
        }
    }

    static func newCachedClaimLedgerStore(_ inner: MemoryClaimLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimLedgerStore {
        return CachedClaimLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim ledgers. Empty fields match all.
    final class ClaimLedgerQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimLedger) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ClaimLedger]) -> [ClaimLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimLedgers(_ store: any ClaimLedgerStore, query: ClaimLedgerQuery) -> [ClaimLedger] {
        return query.apply(store.list())
    }
}
