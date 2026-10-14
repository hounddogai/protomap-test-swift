import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial mappings by code.
    protocol DenialMappingStore {
        func find(_ code: String) -> DenialMapping?
        func save(_ item: DenialMapping)
        func remove(_ code: String) -> Bool
        func list() -> [DenialMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialMappingStore: DenialMappingStore {
        var items: [String: DenialMapping]
        var order: [String]

        init(items: [String: DenialMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialMapping) {
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

        func list() -> [DenialMapping] {
            var out: [DenialMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialMappingStore() -> any DenialMappingStore {
        return MemoryDenialMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialMappingStore: DenialMappingStore {
        var inner: MemoryDenialMappingStore
        var cache: TTLCache<DenialMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialMappingStore, cache: TTLCache<DenialMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialMapping? {
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

        func save(_ item: DenialMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialMapping] {
            return inner.list()
        }
    }

    static func newCachedDenialMappingStore(_ inner: MemoryDenialMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialMappingStore {
        return CachedDenialMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial mappings. Empty fields match all.
    final class DenialMappingQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialMapping) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DenialMapping]) -> [DenialMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialMappings(_ store: any DenialMappingStore, query: DenialMappingQuery) -> [DenialMapping] {
        return query.apply(store.list())
    }
}
