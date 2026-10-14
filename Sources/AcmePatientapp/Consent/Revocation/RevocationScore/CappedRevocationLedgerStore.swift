import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped revocation ledgers by code.
    protocol CappedRevocationLedgerStore {
        func find(_ code: String) -> CappedRevocationLedger?
        func save(_ item: CappedRevocationLedger)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRevocationLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRevocationLedgerStore: CappedRevocationLedgerStore {
        var items: [String: CappedRevocationLedger]
        var order: [String]

        init(items: [String: CappedRevocationLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRevocationLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRevocationLedger) {
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

        func list() -> [CappedRevocationLedger] {
            var out: [CappedRevocationLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRevocationLedgerStore() -> any CappedRevocationLedgerStore {
        return MemoryCappedRevocationLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRevocationLedgerStore: CappedRevocationLedgerStore {
        var inner: MemoryCappedRevocationLedgerStore
        var cache: TTLCache<CappedRevocationLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRevocationLedgerStore, cache: TTLCache<CappedRevocationLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRevocationLedger? {
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

        func save(_ item: CappedRevocationLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRevocationLedger] {
            return inner.list()
        }
    }

    static func newCachedCappedRevocationLedgerStore(_ inner: MemoryCappedRevocationLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRevocationLedgerStore {
        return CachedCappedRevocationLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped revocation ledgers. Empty fields match all.
    final class CappedRevocationLedgerQuery {
        var channel: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRevocationLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRevocationLedger]) -> [CappedRevocationLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRevocationLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRevocationLedgers(_ store: any CappedRevocationLedgerStore, query: CappedRevocationLedgerQuery) -> [CappedRevocationLedger] {
        return query.apply(store.list())
    }
}
