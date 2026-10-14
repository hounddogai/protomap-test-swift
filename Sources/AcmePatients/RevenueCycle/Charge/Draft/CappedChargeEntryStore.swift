import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped charge entries by code.
    protocol CappedChargeEntryStore {
        func find(_ code: String) -> CappedChargeEntry?
        func save(_ item: CappedChargeEntry)
        func remove(_ code: String) -> Bool
        func list() -> [CappedChargeEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedChargeEntryStore: CappedChargeEntryStore {
        var items: [String: CappedChargeEntry]
        var order: [String]

        init(items: [String: CappedChargeEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedChargeEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedChargeEntry) {
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

        func list() -> [CappedChargeEntry] {
            var out: [CappedChargeEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedChargeEntryStore() -> any CappedChargeEntryStore {
        return MemoryCappedChargeEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedChargeEntryStore: CappedChargeEntryStore {
        var inner: MemoryCappedChargeEntryStore
        var cache: TTLCache<CappedChargeEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedChargeEntryStore, cache: TTLCache<CappedChargeEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedChargeEntry? {
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

        func save(_ item: CappedChargeEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedChargeEntry] {
            return inner.list()
        }
    }

    static func newCachedCappedChargeEntryStore(_ inner: MemoryCappedChargeEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedChargeEntryStore {
        return CachedCappedChargeEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped charge entries. Empty fields match all.
    final class CappedChargeEntryQuery {
        var category: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedChargeEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedChargeEntry]) -> [CappedChargeEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedChargeEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedChargeEntries(_ store: any CappedChargeEntryStore, query: CappedChargeEntryQuery) -> [CappedChargeEntry] {
        return query.apply(store.list())
    }
}
