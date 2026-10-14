import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier mappings by code.
    protocol CourierMappingStore {
        func find(_ code: String) -> CourierMapping?
        func save(_ item: CourierMapping)
        func remove(_ code: String) -> Bool
        func list() -> [CourierMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierMappingStore: CourierMappingStore {
        var items: [String: CourierMapping]
        var order: [String]

        init(items: [String: CourierMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierMapping) {
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

        func list() -> [CourierMapping] {
            var out: [CourierMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierMappingStore() -> any CourierMappingStore {
        return MemoryCourierMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierMappingStore: CourierMappingStore {
        var inner: MemoryCourierMappingStore
        var cache: TTLCache<CourierMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierMappingStore, cache: TTLCache<CourierMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierMapping? {
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

        func save(_ item: CourierMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierMapping] {
            return inner.list()
        }
    }

    static func newCachedCourierMappingStore(_ inner: MemoryCourierMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierMappingStore {
        return CachedCourierMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier mappings. Empty fields match all.
    final class CourierMappingQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierMapping]) -> [CourierMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierMappings(_ store: any CourierMappingStore, query: CourierMappingQuery) -> [CourierMapping] {
        return query.apply(store.list())
    }
}
