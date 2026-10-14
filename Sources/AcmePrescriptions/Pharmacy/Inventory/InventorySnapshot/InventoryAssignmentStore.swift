import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory assignments by code.
    protocol InventoryAssignmentStore {
        func find(_ code: String) -> InventoryAssignment?
        func save(_ item: InventoryAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryAssignmentStore: InventoryAssignmentStore {
        var items: [String: InventoryAssignment]
        var order: [String]

        init(items: [String: InventoryAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryAssignment) {
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

        func list() -> [InventoryAssignment] {
            var out: [InventoryAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryAssignmentStore() -> any InventoryAssignmentStore {
        return MemoryInventoryAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryAssignmentStore: InventoryAssignmentStore {
        var inner: MemoryInventoryAssignmentStore
        var cache: TTLCache<InventoryAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryAssignmentStore, cache: TTLCache<InventoryAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryAssignment? {
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

        func save(_ item: InventoryAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryAssignment] {
            return inner.list()
        }
    }

    static func newCachedInventoryAssignmentStore(_ inner: MemoryInventoryAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryAssignmentStore {
        return CachedInventoryAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory assignments. Empty fields match all.
    final class InventoryAssignmentQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [InventoryAssignment]) -> [InventoryAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryAssignments(_ store: any InventoryAssignmentStore, query: InventoryAssignmentQuery) -> [InventoryAssignment] {
        return query.apply(store.list())
    }
}
