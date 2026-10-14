import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan mappings by code.
    protocol DischargePlanMappingStore {
        func find(_ code: String) -> DischargePlanMapping?
        func save(_ item: DischargePlanMapping)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanMappingStore: DischargePlanMappingStore {
        var items: [String: DischargePlanMapping]
        var order: [String]

        init(items: [String: DischargePlanMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanMapping) {
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

        func list() -> [DischargePlanMapping] {
            var out: [DischargePlanMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanMappingStore() -> any DischargePlanMappingStore {
        return MemoryDischargePlanMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanMappingStore: DischargePlanMappingStore {
        var inner: MemoryDischargePlanMappingStore
        var cache: TTLCache<DischargePlanMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanMappingStore, cache: TTLCache<DischargePlanMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanMapping? {
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

        func save(_ item: DischargePlanMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanMapping] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanMappingStore(_ inner: MemoryDischargePlanMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanMappingStore {
        return CachedDischargePlanMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan mappings. Empty fields match all.
    final class DischargePlanMappingQuery {
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

        func matches(_ item: DischargePlanMapping) -> Bool {
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

        func apply(_ items: [DischargePlanMapping]) -> [DischargePlanMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanMappings(_ store: any DischargePlanMappingStore, query: DischargePlanMappingQuery) -> [DischargePlanMapping] {
        return query.apply(store.list())
    }
}
