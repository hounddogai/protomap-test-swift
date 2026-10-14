import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default credential mappings by code.
    protocol DefaultCredentialMappingStore {
        func find(_ code: String) -> DefaultCredentialMapping?
        func save(_ item: DefaultCredentialMapping)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCredentialMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCredentialMappingStore: DefaultCredentialMappingStore {
        var items: [String: DefaultCredentialMapping]
        var order: [String]

        init(items: [String: DefaultCredentialMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCredentialMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCredentialMapping) {
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

        func list() -> [DefaultCredentialMapping] {
            var out: [DefaultCredentialMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCredentialMappingStore() -> any DefaultCredentialMappingStore {
        return MemoryDefaultCredentialMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCredentialMappingStore: DefaultCredentialMappingStore {
        var inner: MemoryDefaultCredentialMappingStore
        var cache: TTLCache<DefaultCredentialMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCredentialMappingStore, cache: TTLCache<DefaultCredentialMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCredentialMapping? {
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

        func save(_ item: DefaultCredentialMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCredentialMapping] {
            return inner.list()
        }
    }

    static func newCachedDefaultCredentialMappingStore(_ inner: MemoryDefaultCredentialMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCredentialMappingStore {
        return CachedDefaultCredentialMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default credential mappings. Empty fields match all.
    final class DefaultCredentialMappingQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCredentialMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCredentialMapping]) -> [DefaultCredentialMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCredentialMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCredentialMappings(_ store: any DefaultCredentialMappingStore, query: DefaultCredentialMappingQuery) -> [DefaultCredentialMapping] {
        return query.apply(store.list())
    }
}
