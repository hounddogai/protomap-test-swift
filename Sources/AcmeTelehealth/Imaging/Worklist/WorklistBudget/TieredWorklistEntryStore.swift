import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered worklist entries by code.
    protocol TieredWorklistEntryStore {
        func find(_ code: String) -> TieredWorklistEntry?
        func save(_ item: TieredWorklistEntry)
        func remove(_ code: String) -> Bool
        func list() -> [TieredWorklistEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredWorklistEntryStore: TieredWorklistEntryStore {
        var items: [String: TieredWorklistEntry]
        var order: [String]

        init(items: [String: TieredWorklistEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredWorklistEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredWorklistEntry) {
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

        func list() -> [TieredWorklistEntry] {
            var out: [TieredWorklistEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredWorklistEntryStore() -> any TieredWorklistEntryStore {
        return MemoryTieredWorklistEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredWorklistEntryStore: TieredWorklistEntryStore {
        var inner: MemoryTieredWorklistEntryStore
        var cache: TTLCache<TieredWorklistEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredWorklistEntryStore, cache: TTLCache<TieredWorklistEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredWorklistEntry? {
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

        func save(_ item: TieredWorklistEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredWorklistEntry] {
            return inner.list()
        }
    }

    static func newCachedTieredWorklistEntryStore(_ inner: MemoryTieredWorklistEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredWorklistEntryStore {
        return CachedTieredWorklistEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered worklist entries. Empty fields match all.
    final class TieredWorklistEntryQuery {
        var segment: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCost: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredWorklistEntry) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredWorklistEntry]) -> [TieredWorklistEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredWorklistEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredWorklistEntries(_ store: any TieredWorklistEntryStore, query: TieredWorklistEntryQuery) -> [TieredWorklistEntry] {
        return query.apply(store.list())
    }
}
