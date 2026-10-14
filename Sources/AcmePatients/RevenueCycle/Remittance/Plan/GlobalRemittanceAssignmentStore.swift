import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global remittance assignments by code.
    protocol GlobalRemittanceAssignmentStore {
        func find(_ code: String) -> GlobalRemittanceAssignment?
        func save(_ item: GlobalRemittanceAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRemittanceAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRemittanceAssignmentStore: GlobalRemittanceAssignmentStore {
        var items: [String: GlobalRemittanceAssignment]
        var order: [String]

        init(items: [String: GlobalRemittanceAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRemittanceAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRemittanceAssignment) {
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

        func list() -> [GlobalRemittanceAssignment] {
            var out: [GlobalRemittanceAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRemittanceAssignmentStore() -> any GlobalRemittanceAssignmentStore {
        return MemoryGlobalRemittanceAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRemittanceAssignmentStore: GlobalRemittanceAssignmentStore {
        var inner: MemoryGlobalRemittanceAssignmentStore
        var cache: TTLCache<GlobalRemittanceAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRemittanceAssignmentStore, cache: TTLCache<GlobalRemittanceAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRemittanceAssignment? {
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

        func save(_ item: GlobalRemittanceAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRemittanceAssignment] {
            return inner.list()
        }
    }

    static func newCachedGlobalRemittanceAssignmentStore(_ inner: MemoryGlobalRemittanceAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRemittanceAssignmentStore {
        return CachedGlobalRemittanceAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global remittance assignments. Empty fields match all.
    final class GlobalRemittanceAssignmentQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRemittanceAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [GlobalRemittanceAssignment]) -> [GlobalRemittanceAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRemittanceAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRemittanceAssignments(_ store: any GlobalRemittanceAssignmentStore, query: GlobalRemittanceAssignmentQuery) -> [GlobalRemittanceAssignment] {
        return query.apply(store.list())
    }
}
