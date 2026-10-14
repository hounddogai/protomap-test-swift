import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered care protocol ledgers by code.
    protocol TieredCareProtocolLedgerStore {
        func find(_ code: String) -> TieredCareProtocolLedger?
        func save(_ item: TieredCareProtocolLedger)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareProtocolLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareProtocolLedgerStore: TieredCareProtocolLedgerStore {
        var items: [String: TieredCareProtocolLedger]
        var order: [String]

        init(items: [String: TieredCareProtocolLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareProtocolLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareProtocolLedger) {
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

        func list() -> [TieredCareProtocolLedger] {
            var out: [TieredCareProtocolLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareProtocolLedgerStore() -> any TieredCareProtocolLedgerStore {
        return MemoryTieredCareProtocolLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareProtocolLedgerStore: TieredCareProtocolLedgerStore {
        var inner: MemoryTieredCareProtocolLedgerStore
        var cache: TTLCache<TieredCareProtocolLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareProtocolLedgerStore, cache: TTLCache<TieredCareProtocolLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareProtocolLedger? {
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

        func save(_ item: TieredCareProtocolLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareProtocolLedger] {
            return inner.list()
        }
    }

    static func newCachedTieredCareProtocolLedgerStore(_ inner: MemoryTieredCareProtocolLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareProtocolLedgerStore {
        return CachedTieredCareProtocolLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care protocol ledgers. Empty fields match all.
    final class TieredCareProtocolLedgerQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareProtocolLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCareProtocolLedger]) -> [TieredCareProtocolLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareProtocolLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareProtocolLedgers(_ store: any TieredCareProtocolLedgerStore, query: TieredCareProtocolLedgerQuery) -> [TieredCareProtocolLedger] {
        return query.apply(store.list())
    }
}
