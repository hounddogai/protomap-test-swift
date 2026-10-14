import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending credential ledgers by code.
    protocol PendingCredentialLedgerStore {
        func find(_ code: String) -> PendingCredentialLedger?
        func save(_ item: PendingCredentialLedger)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCredentialLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCredentialLedgerStore: PendingCredentialLedgerStore {
        var items: [String: PendingCredentialLedger]
        var order: [String]

        init(items: [String: PendingCredentialLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCredentialLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCredentialLedger) {
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

        func list() -> [PendingCredentialLedger] {
            var out: [PendingCredentialLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCredentialLedgerStore() -> any PendingCredentialLedgerStore {
        return MemoryPendingCredentialLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCredentialLedgerStore: PendingCredentialLedgerStore {
        var inner: MemoryPendingCredentialLedgerStore
        var cache: TTLCache<PendingCredentialLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCredentialLedgerStore, cache: TTLCache<PendingCredentialLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCredentialLedger? {
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

        func save(_ item: PendingCredentialLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCredentialLedger] {
            return inner.list()
        }
    }

    static func newCachedPendingCredentialLedgerStore(_ inner: MemoryPendingCredentialLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCredentialLedgerStore {
        return CachedPendingCredentialLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending credential ledgers. Empty fields match all.
    final class PendingCredentialLedgerQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCredentialLedger) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCredentialLedger]) -> [PendingCredentialLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCredentialLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCredentialLedgers(_ store: any PendingCredentialLedgerStore, query: PendingCredentialLedgerQuery) -> [PendingCredentialLedger] {
        return query.apply(store.list())
    }
}
