import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool adjustments by code.
    protocol FloatPoolAdjustmentStore {
        func find(_ code: String) -> FloatPoolAdjustment?
        func save(_ item: FloatPoolAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolAdjustmentStore: FloatPoolAdjustmentStore {
        var items: [String: FloatPoolAdjustment]
        var order: [String]

        init(items: [String: FloatPoolAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolAdjustment) {
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

        func list() -> [FloatPoolAdjustment] {
            var out: [FloatPoolAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolAdjustmentStore() -> any FloatPoolAdjustmentStore {
        return MemoryFloatPoolAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolAdjustmentStore: FloatPoolAdjustmentStore {
        var inner: MemoryFloatPoolAdjustmentStore
        var cache: TTLCache<FloatPoolAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolAdjustmentStore, cache: TTLCache<FloatPoolAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolAdjustment? {
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

        func save(_ item: FloatPoolAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolAdjustment] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolAdjustmentStore(_ inner: MemoryFloatPoolAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolAdjustmentStore {
        return CachedFloatPoolAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool adjustments. Empty fields match all.
    final class FloatPoolAdjustmentQuery {
        var region: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMargin: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolAdjustment) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [FloatPoolAdjustment]) -> [FloatPoolAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolAdjustments(_ store: any FloatPoolAdjustmentStore, query: FloatPoolAdjustmentQuery) -> [FloatPoolAdjustment] {
        return query.apply(store.list())
    }
}
