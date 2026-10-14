import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global shift variances by code.
    protocol GlobalShiftVarianceStore {
        func find(_ code: String) -> GlobalShiftVariance?
        func save(_ item: GlobalShiftVariance)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalShiftVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalShiftVarianceStore: GlobalShiftVarianceStore {
        var items: [String: GlobalShiftVariance]
        var order: [String]

        init(items: [String: GlobalShiftVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalShiftVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalShiftVariance) {
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

        func list() -> [GlobalShiftVariance] {
            var out: [GlobalShiftVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalShiftVarianceStore() -> any GlobalShiftVarianceStore {
        return MemoryGlobalShiftVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalShiftVarianceStore: GlobalShiftVarianceStore {
        var inner: MemoryGlobalShiftVarianceStore
        var cache: TTLCache<GlobalShiftVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalShiftVarianceStore, cache: TTLCache<GlobalShiftVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalShiftVariance? {
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

        func save(_ item: GlobalShiftVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalShiftVariance] {
            return inner.list()
        }
    }

    static func newCachedGlobalShiftVarianceStore(_ inner: MemoryGlobalShiftVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalShiftVarianceStore {
        return CachedGlobalShiftVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global shift variances. Empty fields match all.
    final class GlobalShiftVarianceQuery {
        var unit: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMargin: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalShiftVariance) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalShiftVariance]) -> [GlobalShiftVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalShiftVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalShiftVariances(_ store: any GlobalShiftVarianceStore, query: GlobalShiftVarianceQuery) -> [GlobalShiftVariance] {
        return query.apply(store.list())
    }
}
