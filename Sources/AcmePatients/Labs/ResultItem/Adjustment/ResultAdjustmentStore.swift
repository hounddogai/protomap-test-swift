import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result adjustments by code.
    protocol ResultAdjustmentStore {
        func find(_ code: String) -> ResultAdjustment?
        func save(_ item: ResultAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ResultAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultAdjustmentStore: ResultAdjustmentStore {
        var items: [String: ResultAdjustment]
        var order: [String]

        init(items: [String: ResultAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultAdjustment) {
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

        func list() -> [ResultAdjustment] {
            var out: [ResultAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultAdjustmentStore() -> any ResultAdjustmentStore {
        return MemoryResultAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultAdjustmentStore: ResultAdjustmentStore {
        var inner: MemoryResultAdjustmentStore
        var cache: TTLCache<ResultAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultAdjustmentStore, cache: TTLCache<ResultAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultAdjustment? {
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

        func save(_ item: ResultAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultAdjustment] {
            return inner.list()
        }
    }

    static func newCachedResultAdjustmentStore(_ inner: MemoryResultAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultAdjustmentStore {
        return CachedResultAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result adjustments. Empty fields match all.
    final class ResultAdjustmentQuery {
        var unit: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultAdjustment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultAdjustment]) -> [ResultAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultAdjustments(_ store: any ResultAdjustmentStore, query: ResultAdjustmentQuery) -> [ResultAdjustment] {
        return query.apply(store.list())
    }
}
