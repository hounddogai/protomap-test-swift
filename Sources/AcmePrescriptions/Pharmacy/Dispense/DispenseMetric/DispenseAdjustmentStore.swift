import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense adjustments by code.
    protocol DispenseAdjustmentStore {
        func find(_ code: String) -> DispenseAdjustment?
        func save(_ item: DispenseAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseAdjustmentStore: DispenseAdjustmentStore {
        var items: [String: DispenseAdjustment]
        var order: [String]

        init(items: [String: DispenseAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseAdjustment) {
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

        func list() -> [DispenseAdjustment] {
            var out: [DispenseAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseAdjustmentStore() -> any DispenseAdjustmentStore {
        return MemoryDispenseAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseAdjustmentStore: DispenseAdjustmentStore {
        var inner: MemoryDispenseAdjustmentStore
        var cache: TTLCache<DispenseAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseAdjustmentStore, cache: TTLCache<DispenseAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseAdjustment? {
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

        func save(_ item: DispenseAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseAdjustment] {
            return inner.list()
        }
    }

    static func newCachedDispenseAdjustmentStore(_ inner: MemoryDispenseAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseAdjustmentStore {
        return CachedDispenseAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense adjustments. Empty fields match all.
    final class DispenseAdjustmentQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseAdjustment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseAdjustment]) -> [DispenseAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseAdjustments(_ store: any DispenseAdjustmentStore, query: DispenseAdjustmentQuery) -> [DispenseAdjustment] {
        return query.apply(store.list())
    }
}
