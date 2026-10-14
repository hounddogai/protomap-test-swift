import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation mappings by code.
    protocol IsolationMappingStore {
        func find(_ code: String) -> IsolationMapping?
        func save(_ item: IsolationMapping)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationMappingStore: IsolationMappingStore {
        var items: [String: IsolationMapping]
        var order: [String]

        init(items: [String: IsolationMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationMapping) {
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

        func list() -> [IsolationMapping] {
            var out: [IsolationMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationMappingStore() -> any IsolationMappingStore {
        return MemoryIsolationMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationMappingStore: IsolationMappingStore {
        var inner: MemoryIsolationMappingStore
        var cache: TTLCache<IsolationMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationMappingStore, cache: TTLCache<IsolationMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationMapping? {
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

        func save(_ item: IsolationMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationMapping] {
            return inner.list()
        }
    }

    static func newCachedIsolationMappingStore(_ inner: MemoryIsolationMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationMappingStore {
        return CachedIsolationMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation mappings. Empty fields match all.
    final class IsolationMappingQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationMapping]) -> [IsolationMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationMappings(_ store: any IsolationMappingStore, query: IsolationMappingQuery) -> [IsolationMapping] {
        return query.apply(store.list())
    }
}
