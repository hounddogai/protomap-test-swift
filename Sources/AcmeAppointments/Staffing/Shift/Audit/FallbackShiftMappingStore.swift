import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback shift mappings by code.
    protocol FallbackShiftMappingStore {
        func find(_ code: String) -> FallbackShiftMapping?
        func save(_ item: FallbackShiftMapping)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackShiftMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackShiftMappingStore: FallbackShiftMappingStore {
        var items: [String: FallbackShiftMapping]
        var order: [String]

        init(items: [String: FallbackShiftMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackShiftMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackShiftMapping) {
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

        func list() -> [FallbackShiftMapping] {
            var out: [FallbackShiftMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackShiftMappingStore() -> any FallbackShiftMappingStore {
        return MemoryFallbackShiftMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackShiftMappingStore: FallbackShiftMappingStore {
        var inner: MemoryFallbackShiftMappingStore
        var cache: TTLCache<FallbackShiftMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackShiftMappingStore, cache: TTLCache<FallbackShiftMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackShiftMapping? {
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

        func save(_ item: FallbackShiftMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackShiftMapping] {
            return inner.list()
        }
    }

    static func newCachedFallbackShiftMappingStore(_ inner: MemoryFallbackShiftMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackShiftMappingStore {
        return CachedFallbackShiftMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback shift mappings. Empty fields match all.
    final class FallbackShiftMappingQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackShiftMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackShiftMapping]) -> [FallbackShiftMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackShiftMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackShiftMappings(_ store: any FallbackShiftMappingStore, query: FallbackShiftMappingQuery) -> [FallbackShiftMapping] {
        return query.apply(store.list())
    }
}
