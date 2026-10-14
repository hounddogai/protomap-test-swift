import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered acuity plan entries by code.
    protocol TieredAcuityPlanEntryStore {
        func find(_ code: String) -> TieredAcuityPlanEntry?
        func save(_ item: TieredAcuityPlanEntry)
        func remove(_ code: String) -> Bool
        func list() -> [TieredAcuityPlanEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredAcuityPlanEntryStore: TieredAcuityPlanEntryStore {
        var items: [String: TieredAcuityPlanEntry]
        var order: [String]

        init(items: [String: TieredAcuityPlanEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredAcuityPlanEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredAcuityPlanEntry) {
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

        func list() -> [TieredAcuityPlanEntry] {
            var out: [TieredAcuityPlanEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredAcuityPlanEntryStore() -> any TieredAcuityPlanEntryStore {
        return MemoryTieredAcuityPlanEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredAcuityPlanEntryStore: TieredAcuityPlanEntryStore {
        var inner: MemoryTieredAcuityPlanEntryStore
        var cache: TTLCache<TieredAcuityPlanEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredAcuityPlanEntryStore, cache: TTLCache<TieredAcuityPlanEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredAcuityPlanEntry? {
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

        func save(_ item: TieredAcuityPlanEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredAcuityPlanEntry] {
            return inner.list()
        }
    }

    static func newCachedTieredAcuityPlanEntryStore(_ inner: MemoryTieredAcuityPlanEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredAcuityPlanEntryStore {
        return CachedTieredAcuityPlanEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered acuity plan entries. Empty fields match all.
    final class TieredAcuityPlanEntryQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredAcuityPlanEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredAcuityPlanEntry]) -> [TieredAcuityPlanEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredAcuityPlanEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredAcuityPlanEntries(_ store: any TieredAcuityPlanEntryStore, query: TieredAcuityPlanEntryQuery) -> [TieredAcuityPlanEntry] {
        return query.apply(store.list())
    }
}
