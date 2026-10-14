import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift adjustments by code.
    protocol ShiftAdjustmentStore {
        func find(_ code: String) -> ShiftAdjustment?
        func save(_ item: ShiftAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftAdjustmentStore: ShiftAdjustmentStore {
        var items: [String: ShiftAdjustment]
        var order: [String]

        init(items: [String: ShiftAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftAdjustment) {
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

        func list() -> [ShiftAdjustment] {
            var out: [ShiftAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftAdjustmentStore() -> any ShiftAdjustmentStore {
        return MemoryShiftAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftAdjustmentStore: ShiftAdjustmentStore {
        var inner: MemoryShiftAdjustmentStore
        var cache: TTLCache<ShiftAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftAdjustmentStore, cache: TTLCache<ShiftAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftAdjustment? {
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

        func save(_ item: ShiftAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftAdjustment] {
            return inner.list()
        }
    }

    static func newCachedShiftAdjustmentStore(_ inner: MemoryShiftAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftAdjustmentStore {
        return CachedShiftAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift adjustments. Empty fields match all.
    final class ShiftAdjustmentQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftAdjustment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ShiftAdjustment]) -> [ShiftAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftAdjustments(_ store: any ShiftAdjustmentStore, query: ShiftAdjustmentQuery) -> [ShiftAdjustment] {
        return query.apply(store.list())
    }
}
