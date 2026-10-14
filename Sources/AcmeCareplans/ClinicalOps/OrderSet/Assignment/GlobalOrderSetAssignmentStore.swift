import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global order set assignments by code.
    protocol GlobalOrderSetAssignmentStore {
        func find(_ code: String) -> GlobalOrderSetAssignment?
        func save(_ item: GlobalOrderSetAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalOrderSetAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalOrderSetAssignmentStore: GlobalOrderSetAssignmentStore {
        var items: [String: GlobalOrderSetAssignment]
        var order: [String]

        init(items: [String: GlobalOrderSetAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalOrderSetAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalOrderSetAssignment) {
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

        func list() -> [GlobalOrderSetAssignment] {
            var out: [GlobalOrderSetAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalOrderSetAssignmentStore() -> any GlobalOrderSetAssignmentStore {
        return MemoryGlobalOrderSetAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalOrderSetAssignmentStore: GlobalOrderSetAssignmentStore {
        var inner: MemoryGlobalOrderSetAssignmentStore
        var cache: TTLCache<GlobalOrderSetAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalOrderSetAssignmentStore, cache: TTLCache<GlobalOrderSetAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalOrderSetAssignment? {
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

        func save(_ item: GlobalOrderSetAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalOrderSetAssignment] {
            return inner.list()
        }
    }

    static func newCachedGlobalOrderSetAssignmentStore(_ inner: MemoryGlobalOrderSetAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalOrderSetAssignmentStore {
        return CachedGlobalOrderSetAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global order set assignments. Empty fields match all.
    final class GlobalOrderSetAssignmentQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalOrderSetAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalOrderSetAssignment]) -> [GlobalOrderSetAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalOrderSetAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalOrderSetAssignments(_ store: any GlobalOrderSetAssignmentStore, query: GlobalOrderSetAssignmentQuery) -> [GlobalOrderSetAssignment] {
        return query.apply(store.list())
    }
}
