import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending alert ledgers by code.
    protocol PendingAlertLedgerStore {
        func find(_ code: String) -> PendingAlertLedger?
        func save(_ item: PendingAlertLedger)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAlertLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAlertLedgerStore: PendingAlertLedgerStore {
        var items: [String: PendingAlertLedger]
        var order: [String]

        init(items: [String: PendingAlertLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAlertLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAlertLedger) {
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

        func list() -> [PendingAlertLedger] {
            var out: [PendingAlertLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAlertLedgerStore() -> any PendingAlertLedgerStore {
        return MemoryPendingAlertLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAlertLedgerStore: PendingAlertLedgerStore {
        var inner: MemoryPendingAlertLedgerStore
        var cache: TTLCache<PendingAlertLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAlertLedgerStore, cache: TTLCache<PendingAlertLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAlertLedger? {
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

        func save(_ item: PendingAlertLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAlertLedger] {
            return inner.list()
        }
    }

    static func newCachedPendingAlertLedgerStore(_ inner: MemoryPendingAlertLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAlertLedgerStore {
        return CachedPendingAlertLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending alert ledgers. Empty fields match all.
    final class PendingAlertLedgerQuery {
        var channel: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minLimit: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAlertLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingAlertLedger]) -> [PendingAlertLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAlertLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAlertLedgers(_ store: any PendingAlertLedgerStore, query: PendingAlertLedgerQuery) -> [PendingAlertLedger] {
        return query.apply(store.list())
    }
}
