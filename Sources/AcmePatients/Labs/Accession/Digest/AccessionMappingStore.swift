import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession mappings by code.
    protocol AccessionMappingStore {
        func find(_ code: String) -> AccessionMapping?
        func save(_ item: AccessionMapping)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionMappingStore: AccessionMappingStore {
        var items: [String: AccessionMapping]
        var order: [String]

        init(items: [String: AccessionMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionMapping) {
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

        func list() -> [AccessionMapping] {
            var out: [AccessionMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionMappingStore() -> any AccessionMappingStore {
        return MemoryAccessionMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionMappingStore: AccessionMappingStore {
        var inner: MemoryAccessionMappingStore
        var cache: TTLCache<AccessionMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionMappingStore, cache: TTLCache<AccessionMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionMapping? {
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

        func save(_ item: AccessionMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionMapping] {
            return inner.list()
        }
    }

    static func newCachedAccessionMappingStore(_ inner: MemoryAccessionMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionMappingStore {
        return CachedAccessionMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession mappings. Empty fields match all.
    final class AccessionMappingQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionMapping]) -> [AccessionMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionMappings(_ store: any AccessionMappingStore, query: AccessionMappingQuery) -> [AccessionMapping] {
        return query.apply(store.list())
    }
}
