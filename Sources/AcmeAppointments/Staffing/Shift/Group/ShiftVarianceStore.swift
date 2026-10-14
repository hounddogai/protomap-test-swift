import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift variances by code.
    protocol ShiftVarianceStore {
        func find(_ code: String) -> ShiftVariance?
        func save(_ item: ShiftVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftVarianceStore: ShiftVarianceStore {
        var items: [String: ShiftVariance]
        var order: [String]

        init(items: [String: ShiftVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftVariance) {
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

        func list() -> [ShiftVariance] {
            var out: [ShiftVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftVarianceStore() -> any ShiftVarianceStore {
        return MemoryShiftVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftVarianceStore: ShiftVarianceStore {
        var inner: MemoryShiftVarianceStore
        var cache: TTLCache<ShiftVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftVarianceStore, cache: TTLCache<ShiftVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftVariance? {
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

        func save(_ item: ShiftVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftVariance] {
            return inner.list()
        }
    }

    static func newCachedShiftVarianceStore(_ inner: MemoryShiftVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftVarianceStore {
        return CachedShiftVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift variances. Empty fields match all.
    final class ShiftVarianceQuery {
        var facility: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftVariance) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftVariance]) -> [ShiftVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftVariances(_ store: any ShiftVarianceStore, query: ShiftVarianceQuery) -> [ShiftVariance] {
        return query.apply(store.list())
    }
}
