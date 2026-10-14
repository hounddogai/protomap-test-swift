import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual dispense mappings by code.
    protocol ManualDispenseMappingStore {
        func find(_ code: String) -> ManualDispenseMapping?
        func save(_ item: ManualDispenseMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDispenseMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDispenseMappingStore: ManualDispenseMappingStore {
        var items: [String: ManualDispenseMapping]
        var order: [String]

        init(items: [String: ManualDispenseMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDispenseMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDispenseMapping) {
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

        func list() -> [ManualDispenseMapping] {
            var out: [ManualDispenseMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDispenseMappingStore() -> any ManualDispenseMappingStore {
        return MemoryManualDispenseMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDispenseMappingStore: ManualDispenseMappingStore {
        var inner: MemoryManualDispenseMappingStore
        var cache: TTLCache<ManualDispenseMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDispenseMappingStore, cache: TTLCache<ManualDispenseMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDispenseMapping? {
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

        func save(_ item: ManualDispenseMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDispenseMapping] {
            return inner.list()
        }
    }

    static func newCachedManualDispenseMappingStore(_ inner: MemoryManualDispenseMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDispenseMappingStore {
        return CachedManualDispenseMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual dispense mappings. Empty fields match all.
    final class ManualDispenseMappingQuery {
        var ward: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDispenseMapping) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualDispenseMapping]) -> [ManualDispenseMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDispenseMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDispenseMappings(_ store: any ManualDispenseMappingStore, query: ManualDispenseMappingQuery) -> [ManualDispenseMapping] {
        return query.apply(store.list())
    }
}
