import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional closure mappings by code.
    protocol RegionalClosureMappingStore {
        func find(_ code: String) -> RegionalClosureMapping?
        func save(_ item: RegionalClosureMapping)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalClosureMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalClosureMappingStore: RegionalClosureMappingStore {
        var items: [String: RegionalClosureMapping]
        var order: [String]

        init(items: [String: RegionalClosureMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalClosureMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalClosureMapping) {
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

        func list() -> [RegionalClosureMapping] {
            var out: [RegionalClosureMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalClosureMappingStore() -> any RegionalClosureMappingStore {
        return MemoryRegionalClosureMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalClosureMappingStore: RegionalClosureMappingStore {
        var inner: MemoryRegionalClosureMappingStore
        var cache: TTLCache<RegionalClosureMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalClosureMappingStore, cache: TTLCache<RegionalClosureMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalClosureMapping? {
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

        func save(_ item: RegionalClosureMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalClosureMapping] {
            return inner.list()
        }
    }

    static func newCachedRegionalClosureMappingStore(_ inner: MemoryRegionalClosureMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalClosureMappingStore {
        return CachedRegionalClosureMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional closure mappings. Empty fields match all.
    final class RegionalClosureMappingQuery {
        var unit: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minAmount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalClosureMapping) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalClosureMapping]) -> [RegionalClosureMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalClosureMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalClosureMappings(_ store: any RegionalClosureMappingStore, query: RegionalClosureMappingQuery) -> [RegionalClosureMapping] {
        return query.apply(store.list())
    }
}
