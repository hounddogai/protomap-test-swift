import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped overtime mappings by code.
    protocol CappedOvertimeMappingStore {
        func find(_ code: String) -> CappedOvertimeMapping?
        func save(_ item: CappedOvertimeMapping)
        func remove(_ code: String) -> Bool
        func list() -> [CappedOvertimeMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedOvertimeMappingStore: CappedOvertimeMappingStore {
        var items: [String: CappedOvertimeMapping]
        var order: [String]

        init(items: [String: CappedOvertimeMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedOvertimeMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedOvertimeMapping) {
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

        func list() -> [CappedOvertimeMapping] {
            var out: [CappedOvertimeMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedOvertimeMappingStore() -> any CappedOvertimeMappingStore {
        return MemoryCappedOvertimeMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedOvertimeMappingStore: CappedOvertimeMappingStore {
        var inner: MemoryCappedOvertimeMappingStore
        var cache: TTLCache<CappedOvertimeMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedOvertimeMappingStore, cache: TTLCache<CappedOvertimeMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedOvertimeMapping? {
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

        func save(_ item: CappedOvertimeMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedOvertimeMapping] {
            return inner.list()
        }
    }

    static func newCachedCappedOvertimeMappingStore(_ inner: MemoryCappedOvertimeMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedOvertimeMappingStore {
        return CachedCappedOvertimeMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped overtime mappings. Empty fields match all.
    final class CappedOvertimeMappingQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedOvertimeMapping) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedOvertimeMapping]) -> [CappedOvertimeMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedOvertimeMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedOvertimeMappings(_ store: any CappedOvertimeMappingStore, query: CappedOvertimeMappingQuery) -> [CappedOvertimeMapping] {
        return query.apply(store.list())
    }
}
