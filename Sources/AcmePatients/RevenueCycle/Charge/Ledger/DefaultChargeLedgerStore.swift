import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default charge ledgers by code.
    protocol DefaultChargeLedgerStore {
        func find(_ code: String) -> DefaultChargeLedger?
        func save(_ item: DefaultChargeLedger)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultChargeLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultChargeLedgerStore: DefaultChargeLedgerStore {
        var items: [String: DefaultChargeLedger]
        var order: [String]

        init(items: [String: DefaultChargeLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultChargeLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultChargeLedger) {
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

        func list() -> [DefaultChargeLedger] {
            var out: [DefaultChargeLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultChargeLedgerStore() -> any DefaultChargeLedgerStore {
        return MemoryDefaultChargeLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultChargeLedgerStore: DefaultChargeLedgerStore {
        var inner: MemoryDefaultChargeLedgerStore
        var cache: TTLCache<DefaultChargeLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultChargeLedgerStore, cache: TTLCache<DefaultChargeLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultChargeLedger? {
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

        func save(_ item: DefaultChargeLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultChargeLedger] {
            return inner.list()
        }
    }

    static func newCachedDefaultChargeLedgerStore(_ inner: MemoryDefaultChargeLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultChargeLedgerStore {
        return CachedDefaultChargeLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default charge ledgers. Empty fields match all.
    final class DefaultChargeLedgerQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultChargeLedger) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DefaultChargeLedger]) -> [DefaultChargeLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultChargeLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultChargeLedgers(_ store: any DefaultChargeLedgerStore, query: DefaultChargeLedgerQuery) -> [DefaultChargeLedger] {
        return query.apply(store.list())
    }
}
