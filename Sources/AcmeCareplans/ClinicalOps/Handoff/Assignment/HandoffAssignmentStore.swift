import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff assignments by code.
    protocol HandoffAssignmentStore {
        func find(_ code: String) -> HandoffAssignment?
        func save(_ item: HandoffAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffAssignmentStore: HandoffAssignmentStore {
        var items: [String: HandoffAssignment]
        var order: [String]

        init(items: [String: HandoffAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffAssignment) {
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

        func list() -> [HandoffAssignment] {
            var out: [HandoffAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffAssignmentStore() -> any HandoffAssignmentStore {
        return MemoryHandoffAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffAssignmentStore: HandoffAssignmentStore {
        var inner: MemoryHandoffAssignmentStore
        var cache: TTLCache<HandoffAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffAssignmentStore, cache: TTLCache<HandoffAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffAssignment? {
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

        func save(_ item: HandoffAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffAssignment] {
            return inner.list()
        }
    }

    static func newCachedHandoffAssignmentStore(_ inner: MemoryHandoffAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffAssignmentStore {
        return CachedHandoffAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff assignments. Empty fields match all.
    final class HandoffAssignmentQuery {
        var ward: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMargin: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffAssignment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [HandoffAssignment]) -> [HandoffAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffAssignments(_ store: any HandoffAssignmentStore, query: HandoffAssignmentQuery) -> [HandoffAssignment] {
        return query.apply(store.list())
    }
}
