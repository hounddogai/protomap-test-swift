import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback care protocol ledgers by code.
    protocol FallbackCareProtocolLedgerStore {
        func find(_ code: String) -> FallbackCareProtocolLedger?
        func save(_ item: FallbackCareProtocolLedger)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareProtocolLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareProtocolLedgerStore: FallbackCareProtocolLedgerStore {
        var items: [String: FallbackCareProtocolLedger]
        var order: [String]

        init(items: [String: FallbackCareProtocolLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareProtocolLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareProtocolLedger) {
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

        func list() -> [FallbackCareProtocolLedger] {
            var out: [FallbackCareProtocolLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareProtocolLedgerStore() -> any FallbackCareProtocolLedgerStore {
        return MemoryFallbackCareProtocolLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareProtocolLedgerStore: FallbackCareProtocolLedgerStore {
        var inner: MemoryFallbackCareProtocolLedgerStore
        var cache: TTLCache<FallbackCareProtocolLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareProtocolLedgerStore, cache: TTLCache<FallbackCareProtocolLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareProtocolLedger? {
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

        func save(_ item: FallbackCareProtocolLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareProtocolLedger] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareProtocolLedgerStore(_ inner: MemoryFallbackCareProtocolLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareProtocolLedgerStore {
        return CachedFallbackCareProtocolLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care protocol ledgers. Empty fields match all.
    final class FallbackCareProtocolLedgerQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareProtocolLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [FallbackCareProtocolLedger]) -> [FallbackCareProtocolLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareProtocolLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareProtocolLedgers(_ store: any FallbackCareProtocolLedgerStore, query: FallbackCareProtocolLedgerQuery) -> [FallbackCareProtocolLedger] {
        return query.apply(store.list())
    }
}
