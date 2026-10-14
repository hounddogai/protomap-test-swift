import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped credential ledgers by code.
    protocol CappedCredentialLedgerStore {
        func find(_ code: String) -> CappedCredentialLedger?
        func save(_ item: CappedCredentialLedger)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCredentialLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCredentialLedgerStore: CappedCredentialLedgerStore {
        var items: [String: CappedCredentialLedger]
        var order: [String]

        init(items: [String: CappedCredentialLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCredentialLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCredentialLedger) {
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

        func list() -> [CappedCredentialLedger] {
            var out: [CappedCredentialLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCredentialLedgerStore() -> any CappedCredentialLedgerStore {
        return MemoryCappedCredentialLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCredentialLedgerStore: CappedCredentialLedgerStore {
        var inner: MemoryCappedCredentialLedgerStore
        var cache: TTLCache<CappedCredentialLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCredentialLedgerStore, cache: TTLCache<CappedCredentialLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCredentialLedger? {
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

        func save(_ item: CappedCredentialLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCredentialLedger] {
            return inner.list()
        }
    }

    static func newCachedCappedCredentialLedgerStore(_ inner: MemoryCappedCredentialLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCredentialLedgerStore {
        return CachedCappedCredentialLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped credential ledgers. Empty fields match all.
    final class CappedCredentialLedgerQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCredentialLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCredentialLedger]) -> [CappedCredentialLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCredentialLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCredentialLedgers(_ store: any CappedCredentialLedgerStore, query: CappedCredentialLedgerQuery) -> [CappedCredentialLedger] {
        return query.apply(store.list())
    }
}
