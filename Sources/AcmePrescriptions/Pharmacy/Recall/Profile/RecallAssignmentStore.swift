import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall assignments by code.
    protocol RecallAssignmentStore {
        func find(_ code: String) -> RecallAssignment?
        func save(_ item: RecallAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RecallAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallAssignmentStore: RecallAssignmentStore {
        var items: [String: RecallAssignment]
        var order: [String]

        init(items: [String: RecallAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallAssignment) {
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

        func list() -> [RecallAssignment] {
            var out: [RecallAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallAssignmentStore() -> any RecallAssignmentStore {
        return MemoryRecallAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallAssignmentStore: RecallAssignmentStore {
        var inner: MemoryRecallAssignmentStore
        var cache: TTLCache<RecallAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallAssignmentStore, cache: TTLCache<RecallAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallAssignment? {
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

        func save(_ item: RecallAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallAssignment] {
            return inner.list()
        }
    }

    static func newCachedRecallAssignmentStore(_ inner: MemoryRecallAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallAssignmentStore {
        return CachedRecallAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall assignments. Empty fields match all.
    final class RecallAssignmentQuery {
        var unit: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallAssignment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RecallAssignment]) -> [RecallAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallAssignments(_ store: any RecallAssignmentStore, query: RecallAssignmentQuery) -> [RecallAssignment] {
        return query.apply(store.list())
    }
}
