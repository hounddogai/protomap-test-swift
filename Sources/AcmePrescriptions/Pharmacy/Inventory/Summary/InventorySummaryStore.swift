import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory summaries by code.
    protocol InventorySummaryStore {
        func find(_ code: String) -> InventorySummary?
        func save(_ item: InventorySummary)
        func remove(_ code: String) -> Bool
        func list() -> [InventorySummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventorySummaryStore: InventorySummaryStore {
        var items: [String: InventorySummary]
        var order: [String]

        init(items: [String: InventorySummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventorySummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventorySummary) {
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

        func list() -> [InventorySummary] {
            var out: [InventorySummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventorySummaryStore() -> any InventorySummaryStore {
        return MemoryInventorySummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventorySummaryStore: InventorySummaryStore {
        var inner: MemoryInventorySummaryStore
        var cache: TTLCache<InventorySummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventorySummaryStore, cache: TTLCache<InventorySummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventorySummary? {
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

        func save(_ item: InventorySummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventorySummary] {
            return inner.list()
        }
    }

    static func newCachedInventorySummaryStore(_ inner: MemoryInventorySummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventorySummaryStore {
        return CachedInventorySummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory summaries. Empty fields match all.
    final class InventorySummaryQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventorySummary) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventorySummary]) -> [InventorySummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventorySummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventorySummaries(_ store: any InventorySummaryStore, query: InventorySummaryQuery) -> [InventorySummary] {
        return query.apply(store.list())
    }
}
