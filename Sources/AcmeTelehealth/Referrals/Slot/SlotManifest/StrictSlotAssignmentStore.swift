import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict slot assignments by code.
    protocol StrictSlotAssignmentStore {
        func find(_ code: String) -> StrictSlotAssignment?
        func save(_ item: StrictSlotAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSlotAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSlotAssignmentStore: StrictSlotAssignmentStore {
        var items: [String: StrictSlotAssignment]
        var order: [String]

        init(items: [String: StrictSlotAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSlotAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSlotAssignment) {
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

        func list() -> [StrictSlotAssignment] {
            var out: [StrictSlotAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSlotAssignmentStore() -> any StrictSlotAssignmentStore {
        return MemoryStrictSlotAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSlotAssignmentStore: StrictSlotAssignmentStore {
        var inner: MemoryStrictSlotAssignmentStore
        var cache: TTLCache<StrictSlotAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSlotAssignmentStore, cache: TTLCache<StrictSlotAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSlotAssignment? {
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

        func save(_ item: StrictSlotAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSlotAssignment] {
            return inner.list()
        }
    }

    static func newCachedStrictSlotAssignmentStore(_ inner: MemoryStrictSlotAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSlotAssignmentStore {
        return CachedStrictSlotAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict slot assignments. Empty fields match all.
    final class StrictSlotAssignmentQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSlotAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSlotAssignment]) -> [StrictSlotAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSlotAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSlotAssignments(_ store: any StrictSlotAssignmentStore, query: StrictSlotAssignmentQuery) -> [StrictSlotAssignment] {
        return query.apply(store.list())
    }
}
