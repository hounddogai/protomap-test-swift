import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered read ledgers by code.
    protocol TieredReadLedgerStore {
        func find(_ code: String) -> TieredReadLedger?
        func save(_ item: TieredReadLedger)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReadLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReadLedgerStore: TieredReadLedgerStore {
        var items: [String: TieredReadLedger]
        var order: [String]

        init(items: [String: TieredReadLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReadLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReadLedger) {
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

        func list() -> [TieredReadLedger] {
            var out: [TieredReadLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReadLedgerStore() -> any TieredReadLedgerStore {
        return MemoryTieredReadLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReadLedgerStore: TieredReadLedgerStore {
        var inner: MemoryTieredReadLedgerStore
        var cache: TTLCache<TieredReadLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReadLedgerStore, cache: TTLCache<TieredReadLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReadLedger? {
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

        func save(_ item: TieredReadLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReadLedger] {
            return inner.list()
        }
    }

    static func newCachedTieredReadLedgerStore(_ inner: MemoryTieredReadLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReadLedgerStore {
        return CachedTieredReadLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered read ledgers. Empty fields match all.
    final class TieredReadLedgerQuery {
        var source: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCopay: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReadLedger) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [TieredReadLedger]) -> [TieredReadLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReadLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReadLedgers(_ store: any TieredReadLedgerStore, query: TieredReadLedgerQuery) -> [TieredReadLedger] {
        return query.apply(store.list())
    }
}
