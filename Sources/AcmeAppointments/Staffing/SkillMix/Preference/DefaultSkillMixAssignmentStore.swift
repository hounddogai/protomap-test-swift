import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default skill mix assignments by code.
    protocol DefaultSkillMixAssignmentStore {
        func find(_ code: String) -> DefaultSkillMixAssignment?
        func save(_ item: DefaultSkillMixAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSkillMixAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSkillMixAssignmentStore: DefaultSkillMixAssignmentStore {
        var items: [String: DefaultSkillMixAssignment]
        var order: [String]

        init(items: [String: DefaultSkillMixAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSkillMixAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSkillMixAssignment) {
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

        func list() -> [DefaultSkillMixAssignment] {
            var out: [DefaultSkillMixAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSkillMixAssignmentStore() -> any DefaultSkillMixAssignmentStore {
        return MemoryDefaultSkillMixAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSkillMixAssignmentStore: DefaultSkillMixAssignmentStore {
        var inner: MemoryDefaultSkillMixAssignmentStore
        var cache: TTLCache<DefaultSkillMixAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSkillMixAssignmentStore, cache: TTLCache<DefaultSkillMixAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSkillMixAssignment? {
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

        func save(_ item: DefaultSkillMixAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSkillMixAssignment] {
            return inner.list()
        }
    }

    static func newCachedDefaultSkillMixAssignmentStore(_ inner: MemoryDefaultSkillMixAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSkillMixAssignmentStore {
        return CachedDefaultSkillMixAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default skill mix assignments. Empty fields match all.
    final class DefaultSkillMixAssignmentQuery {
        var ward: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSkillMixAssignment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultSkillMixAssignment]) -> [DefaultSkillMixAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSkillMixAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSkillMixAssignments(_ store: any DefaultSkillMixAssignmentStore, query: DefaultSkillMixAssignmentQuery) -> [DefaultSkillMixAssignment] {
        return query.apply(store.list())
    }
}
