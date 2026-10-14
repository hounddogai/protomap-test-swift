import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim mappings by code.
    protocol ClaimMappingStore {
        func find(_ code: String) -> ClaimMapping?
        func save(_ item: ClaimMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimMappingStore: ClaimMappingStore {
        var items: [String: ClaimMapping]
        var order: [String]

        init(items: [String: ClaimMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimMapping) {
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

        func list() -> [ClaimMapping] {
            var out: [ClaimMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimMappingStore() -> any ClaimMappingStore {
        return MemoryClaimMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimMappingStore: ClaimMappingStore {
        var inner: MemoryClaimMappingStore
        var cache: TTLCache<ClaimMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimMappingStore, cache: TTLCache<ClaimMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimMapping? {
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

        func save(_ item: ClaimMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimMapping] {
            return inner.list()
        }
    }

    static func newCachedClaimMappingStore(_ inner: MemoryClaimMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimMappingStore {
        return CachedClaimMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim mappings. Empty fields match all.
    final class ClaimMappingQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimMapping]) -> [ClaimMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimMappings(_ store: any ClaimMappingStore, query: ClaimMappingQuery) -> [ClaimMapping] {
        return query.apply(store.list())
    }
}
