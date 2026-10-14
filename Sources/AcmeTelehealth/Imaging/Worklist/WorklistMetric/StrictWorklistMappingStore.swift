import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict worklist mappings by code.
    protocol StrictWorklistMappingStore {
        func find(_ code: String) -> StrictWorklistMapping?
        func save(_ item: StrictWorklistMapping)
        func remove(_ code: String) -> Bool
        func list() -> [StrictWorklistMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictWorklistMappingStore: StrictWorklistMappingStore {
        var items: [String: StrictWorklistMapping]
        var order: [String]

        init(items: [String: StrictWorklistMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictWorklistMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictWorklistMapping) {
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

        func list() -> [StrictWorklistMapping] {
            var out: [StrictWorklistMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictWorklistMappingStore() -> any StrictWorklistMappingStore {
        return MemoryStrictWorklistMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictWorklistMappingStore: StrictWorklistMappingStore {
        var inner: MemoryStrictWorklistMappingStore
        var cache: TTLCache<StrictWorklistMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictWorklistMappingStore, cache: TTLCache<StrictWorklistMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictWorklistMapping? {
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

        func save(_ item: StrictWorklistMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictWorklistMapping] {
            return inner.list()
        }
    }

    static func newCachedStrictWorklistMappingStore(_ inner: MemoryStrictWorklistMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictWorklistMappingStore {
        return CachedStrictWorklistMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict worklist mappings. Empty fields match all.
    final class StrictWorklistMappingQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictWorklistMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictWorklistMapping]) -> [StrictWorklistMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictWorklistMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictWorklistMappings(_ store: any StrictWorklistMappingStore, query: StrictWorklistMappingQuery) -> [StrictWorklistMapping] {
        return query.apply(store.list())
    }
}
