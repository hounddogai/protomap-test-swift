import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global courier mappings by code.
    protocol GlobalCourierMappingStore {
        func find(_ code: String) -> GlobalCourierMapping?
        func save(_ item: GlobalCourierMapping)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCourierMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCourierMappingStore: GlobalCourierMappingStore {
        var items: [String: GlobalCourierMapping]
        var order: [String]

        init(items: [String: GlobalCourierMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCourierMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCourierMapping) {
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

        func list() -> [GlobalCourierMapping] {
            var out: [GlobalCourierMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCourierMappingStore() -> any GlobalCourierMappingStore {
        return MemoryGlobalCourierMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCourierMappingStore: GlobalCourierMappingStore {
        var inner: MemoryGlobalCourierMappingStore
        var cache: TTLCache<GlobalCourierMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCourierMappingStore, cache: TTLCache<GlobalCourierMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCourierMapping? {
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

        func save(_ item: GlobalCourierMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCourierMapping] {
            return inner.list()
        }
    }

    static func newCachedGlobalCourierMappingStore(_ inner: MemoryGlobalCourierMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCourierMappingStore {
        return CachedGlobalCourierMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global courier mappings. Empty fields match all.
    final class GlobalCourierMappingQuery {
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

        func matches(_ item: GlobalCourierMapping) -> Bool {
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

        func apply(_ items: [GlobalCourierMapping]) -> [GlobalCourierMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCourierMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCourierMappings(_ store: any GlobalCourierMappingStore, query: GlobalCourierMappingQuery) -> [GlobalCourierMapping] {
        return query.apply(store.list())
    }
}
