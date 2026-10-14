import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global transfer assignments by code.
    protocol GlobalTransferAssignmentStore {
        func find(_ code: String) -> GlobalTransferAssignment?
        func save(_ item: GlobalTransferAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalTransferAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalTransferAssignmentStore: GlobalTransferAssignmentStore {
        var items: [String: GlobalTransferAssignment]
        var order: [String]

        init(items: [String: GlobalTransferAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalTransferAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalTransferAssignment) {
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

        func list() -> [GlobalTransferAssignment] {
            var out: [GlobalTransferAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalTransferAssignmentStore() -> any GlobalTransferAssignmentStore {
        return MemoryGlobalTransferAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalTransferAssignmentStore: GlobalTransferAssignmentStore {
        var inner: MemoryGlobalTransferAssignmentStore
        var cache: TTLCache<GlobalTransferAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalTransferAssignmentStore, cache: TTLCache<GlobalTransferAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalTransferAssignment? {
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

        func save(_ item: GlobalTransferAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalTransferAssignment] {
            return inner.list()
        }
    }

    static func newCachedGlobalTransferAssignmentStore(_ inner: MemoryGlobalTransferAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalTransferAssignmentStore {
        return CachedGlobalTransferAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global transfer assignments. Empty fields match all.
    final class GlobalTransferAssignmentQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalTransferAssignment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalTransferAssignment]) -> [GlobalTransferAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalTransferAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalTransferAssignments(_ store: any GlobalTransferAssignmentStore, query: GlobalTransferAssignmentQuery) -> [GlobalTransferAssignment] {
        return query.apply(store.list())
    }
}
