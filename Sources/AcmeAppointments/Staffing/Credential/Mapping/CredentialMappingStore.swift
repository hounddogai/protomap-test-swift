import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential mappings by code.
    protocol CredentialMappingStore {
        func find(_ code: String) -> CredentialMapping?
        func save(_ item: CredentialMapping)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialMappingStore: CredentialMappingStore {
        var items: [String: CredentialMapping]
        var order: [String]

        init(items: [String: CredentialMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialMapping) {
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

        func list() -> [CredentialMapping] {
            var out: [CredentialMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialMappingStore() -> any CredentialMappingStore {
        return MemoryCredentialMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialMappingStore: CredentialMappingStore {
        var inner: MemoryCredentialMappingStore
        var cache: TTLCache<CredentialMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialMappingStore, cache: TTLCache<CredentialMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialMapping? {
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

        func save(_ item: CredentialMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialMapping] {
            return inner.list()
        }
    }

    static func newCachedCredentialMappingStore(_ inner: MemoryCredentialMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialMappingStore {
        return CachedCredentialMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential mappings. Empty fields match all.
    final class CredentialMappingQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialMapping) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialMapping]) -> [CredentialMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialMappings(_ store: any CredentialMappingStore, query: CredentialMappingQuery) -> [CredentialMapping] {
        return query.apply(store.list())
    }
}
