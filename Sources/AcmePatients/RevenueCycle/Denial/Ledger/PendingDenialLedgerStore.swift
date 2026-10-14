import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending denial ledgers by code.
    protocol PendingDenialLedgerStore {
        func find(_ code: String) -> PendingDenialLedger?
        func save(_ item: PendingDenialLedger)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDenialLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDenialLedgerStore: PendingDenialLedgerStore {
        var items: [String: PendingDenialLedger]
        var order: [String]

        init(items: [String: PendingDenialLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDenialLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDenialLedger) {
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

        func list() -> [PendingDenialLedger] {
            var out: [PendingDenialLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDenialLedgerStore() -> any PendingDenialLedgerStore {
        return MemoryPendingDenialLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDenialLedgerStore: PendingDenialLedgerStore {
        var inner: MemoryPendingDenialLedgerStore
        var cache: TTLCache<PendingDenialLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDenialLedgerStore, cache: TTLCache<PendingDenialLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDenialLedger? {
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

        func save(_ item: PendingDenialLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDenialLedger] {
            return inner.list()
        }
    }

    static func newCachedPendingDenialLedgerStore(_ inner: MemoryPendingDenialLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDenialLedgerStore {
        return CachedPendingDenialLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending denial ledgers. Empty fields match all.
    final class PendingDenialLedgerQuery {
        var category: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minSequence: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDenialLedger) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingDenialLedger]) -> [PendingDenialLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDenialLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDenialLedgers(_ store: any PendingDenialLedgerStore, query: PendingDenialLedgerQuery) -> [PendingDenialLedger] {
        return query.apply(store.list())
    }
}
