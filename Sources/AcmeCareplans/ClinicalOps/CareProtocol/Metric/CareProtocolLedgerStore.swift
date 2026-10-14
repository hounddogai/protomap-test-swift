import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol ledgers by code.
    protocol CareProtocolLedgerStore {
        func find(_ code: String) -> CareProtocolLedger?
        func save(_ item: CareProtocolLedger)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolLedgerStore: CareProtocolLedgerStore {
        var items: [String: CareProtocolLedger]
        var order: [String]

        init(items: [String: CareProtocolLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolLedger) {
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

        func list() -> [CareProtocolLedger] {
            var out: [CareProtocolLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolLedgerStore() -> any CareProtocolLedgerStore {
        return MemoryCareProtocolLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolLedgerStore: CareProtocolLedgerStore {
        var inner: MemoryCareProtocolLedgerStore
        var cache: TTLCache<CareProtocolLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolLedgerStore, cache: TTLCache<CareProtocolLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolLedger? {
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

        func save(_ item: CareProtocolLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolLedger] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolLedgerStore(_ inner: MemoryCareProtocolLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolLedgerStore {
        return CachedCareProtocolLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol ledgers. Empty fields match all.
    final class CareProtocolLedgerQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolLedger]) -> [CareProtocolLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolLedgers(_ store: any CareProtocolLedgerStore, query: CareProtocolLedgerQuery) -> [CareProtocolLedger] {
        return query.apply(store.list())
    }
}
