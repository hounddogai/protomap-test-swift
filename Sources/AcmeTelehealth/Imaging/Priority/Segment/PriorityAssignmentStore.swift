import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority assignments by code.
    protocol PriorityAssignmentStore {
        func find(_ code: String) -> PriorityAssignment?
        func save(_ item: PriorityAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityAssignmentStore: PriorityAssignmentStore {
        var items: [String: PriorityAssignment]
        var order: [String]

        init(items: [String: PriorityAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityAssignment) {
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

        func list() -> [PriorityAssignment] {
            var out: [PriorityAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityAssignmentStore() -> any PriorityAssignmentStore {
        return MemoryPriorityAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityAssignmentStore: PriorityAssignmentStore {
        var inner: MemoryPriorityAssignmentStore
        var cache: TTLCache<PriorityAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityAssignmentStore, cache: TTLCache<PriorityAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityAssignment? {
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

        func save(_ item: PriorityAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityAssignment] {
            return inner.list()
        }
    }

    static func newCachedPriorityAssignmentStore(_ inner: MemoryPriorityAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityAssignmentStore {
        return CachedPriorityAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority assignments. Empty fields match all.
    final class PriorityAssignmentQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityAssignment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityAssignment]) -> [PriorityAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityAssignments(_ store: any PriorityAssignmentStore, query: PriorityAssignmentQuery) -> [PriorityAssignment] {
        return query.apply(store.list())
    }
}
