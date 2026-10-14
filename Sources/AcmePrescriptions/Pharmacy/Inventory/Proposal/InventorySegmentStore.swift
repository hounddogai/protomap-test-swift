import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory segments by code.
    protocol InventorySegmentStore {
        func find(_ code: String) -> InventorySegment?
        func save(_ item: InventorySegment)
        func remove(_ code: String) -> Bool
        func list() -> [InventorySegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventorySegmentStore: InventorySegmentStore {
        var items: [String: InventorySegment]
        var order: [String]

        init(items: [String: InventorySegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventorySegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventorySegment) {
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

        func list() -> [InventorySegment] {
            var out: [InventorySegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventorySegmentStore() -> any InventorySegmentStore {
        return MemoryInventorySegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventorySegmentStore: InventorySegmentStore {
        var inner: MemoryInventorySegmentStore
        var cache: TTLCache<InventorySegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventorySegmentStore, cache: TTLCache<InventorySegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventorySegment? {
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

        func save(_ item: InventorySegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventorySegment] {
            return inner.list()
        }
    }

    static func newCachedInventorySegmentStore(_ inner: MemoryInventorySegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventorySegmentStore {
        return CachedInventorySegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory segments. Empty fields match all.
    final class InventorySegmentQuery {
        var source: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventorySegment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventorySegment]) -> [InventorySegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventorySegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventorySegments(_ store: any InventorySegmentStore, query: InventorySegmentQuery) -> [InventorySegment] {
        return query.apply(store.list())
    }
}
