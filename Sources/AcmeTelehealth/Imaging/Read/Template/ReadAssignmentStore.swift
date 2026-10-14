import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read assignments by code.
    protocol ReadAssignmentStore {
        func find(_ code: String) -> ReadAssignment?
        func save(_ item: ReadAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ReadAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadAssignmentStore: ReadAssignmentStore {
        var items: [String: ReadAssignment]
        var order: [String]

        init(items: [String: ReadAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadAssignment) {
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

        func list() -> [ReadAssignment] {
            var out: [ReadAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadAssignmentStore() -> any ReadAssignmentStore {
        return MemoryReadAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadAssignmentStore: ReadAssignmentStore {
        var inner: MemoryReadAssignmentStore
        var cache: TTLCache<ReadAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadAssignmentStore, cache: TTLCache<ReadAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadAssignment? {
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

        func save(_ item: ReadAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadAssignment] {
            return inner.list()
        }
    }

    static func newCachedReadAssignmentStore(_ inner: MemoryReadAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadAssignmentStore {
        return CachedReadAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read assignments. Empty fields match all.
    final class ReadAssignmentQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadAssignment]) -> [ReadAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadAssignments(_ store: any ReadAssignmentStore, query: ReadAssignmentQuery) -> [ReadAssignment] {
        return query.apply(store.list())
    }
}
