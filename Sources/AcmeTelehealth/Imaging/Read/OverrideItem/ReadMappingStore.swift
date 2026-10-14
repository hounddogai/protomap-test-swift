import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read mappings by code.
    protocol ReadMappingStore {
        func find(_ code: String) -> ReadMapping?
        func save(_ item: ReadMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ReadMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadMappingStore: ReadMappingStore {
        var items: [String: ReadMapping]
        var order: [String]

        init(items: [String: ReadMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadMapping) {
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

        func list() -> [ReadMapping] {
            var out: [ReadMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadMappingStore() -> any ReadMappingStore {
        return MemoryReadMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadMappingStore: ReadMappingStore {
        var inner: MemoryReadMappingStore
        var cache: TTLCache<ReadMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadMappingStore, cache: TTLCache<ReadMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadMapping? {
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

        func save(_ item: ReadMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadMapping] {
            return inner.list()
        }
    }

    static func newCachedReadMappingStore(_ inner: MemoryReadMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadMappingStore {
        return CachedReadMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read mappings. Empty fields match all.
    final class ReadMappingQuery {
        var region: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minLimit: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadMapping) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadMapping]) -> [ReadMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadMappings(_ store: any ReadMappingStore, query: ReadMappingQuery) -> [ReadMapping] {
        return query.apply(store.list())
    }
}
