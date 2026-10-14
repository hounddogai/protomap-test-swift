import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered interaction ledgers by code.
    protocol TieredInteractionLedgerStore {
        func find(_ code: String) -> TieredInteractionLedger?
        func save(_ item: TieredInteractionLedger)
        func remove(_ code: String) -> Bool
        func list() -> [TieredInteractionLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredInteractionLedgerStore: TieredInteractionLedgerStore {
        var items: [String: TieredInteractionLedger]
        var order: [String]

        init(items: [String: TieredInteractionLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredInteractionLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredInteractionLedger) {
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

        func list() -> [TieredInteractionLedger] {
            var out: [TieredInteractionLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredInteractionLedgerStore() -> any TieredInteractionLedgerStore {
        return MemoryTieredInteractionLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredInteractionLedgerStore: TieredInteractionLedgerStore {
        var inner: MemoryTieredInteractionLedgerStore
        var cache: TTLCache<TieredInteractionLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredInteractionLedgerStore, cache: TTLCache<TieredInteractionLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredInteractionLedger? {
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

        func save(_ item: TieredInteractionLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredInteractionLedger] {
            return inner.list()
        }
    }

    static func newCachedTieredInteractionLedgerStore(_ inner: MemoryTieredInteractionLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredInteractionLedgerStore {
        return CachedTieredInteractionLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered interaction ledgers. Empty fields match all.
    final class TieredInteractionLedgerQuery {
        var source: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMargin: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredInteractionLedger) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredInteractionLedger]) -> [TieredInteractionLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredInteractionLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredInteractionLedgers(_ store: any TieredInteractionLedgerStore, query: TieredInteractionLedgerQuery) -> [TieredInteractionLedger] {
        return query.apply(store.list())
    }
}
