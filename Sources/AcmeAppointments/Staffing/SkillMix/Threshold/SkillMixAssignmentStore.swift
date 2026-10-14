import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix assignments by code.
    protocol SkillMixAssignmentStore {
        func find(_ code: String) -> SkillMixAssignment?
        func save(_ item: SkillMixAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixAssignmentStore: SkillMixAssignmentStore {
        var items: [String: SkillMixAssignment]
        var order: [String]

        init(items: [String: SkillMixAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixAssignment) {
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

        func list() -> [SkillMixAssignment] {
            var out: [SkillMixAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixAssignmentStore() -> any SkillMixAssignmentStore {
        return MemorySkillMixAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixAssignmentStore: SkillMixAssignmentStore {
        var inner: MemorySkillMixAssignmentStore
        var cache: TTLCache<SkillMixAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixAssignmentStore, cache: TTLCache<SkillMixAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixAssignment? {
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

        func save(_ item: SkillMixAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixAssignment] {
            return inner.list()
        }
    }

    static func newCachedSkillMixAssignmentStore(_ inner: MemorySkillMixAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixAssignmentStore {
        return CachedSkillMixAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix assignments. Empty fields match all.
    final class SkillMixAssignmentQuery {
        var ward: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixAssignment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixAssignment]) -> [SkillMixAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixAssignments(_ store: any SkillMixAssignmentStore, query: SkillMixAssignmentQuery) -> [SkillMixAssignment] {
        return query.apply(store.list())
    }
}
