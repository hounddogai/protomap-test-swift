import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient skill mix assignments by code.
    protocol LenientSkillMixAssignmentStore {
        func find(_ code: String) -> LenientSkillMixAssignment?
        func save(_ item: LenientSkillMixAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSkillMixAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSkillMixAssignmentStore: LenientSkillMixAssignmentStore {
        var items: [String: LenientSkillMixAssignment]
        var order: [String]

        init(items: [String: LenientSkillMixAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSkillMixAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSkillMixAssignment) {
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

        func list() -> [LenientSkillMixAssignment] {
            var out: [LenientSkillMixAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSkillMixAssignmentStore() -> any LenientSkillMixAssignmentStore {
        return MemoryLenientSkillMixAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSkillMixAssignmentStore: LenientSkillMixAssignmentStore {
        var inner: MemoryLenientSkillMixAssignmentStore
        var cache: TTLCache<LenientSkillMixAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSkillMixAssignmentStore, cache: TTLCache<LenientSkillMixAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSkillMixAssignment? {
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

        func save(_ item: LenientSkillMixAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSkillMixAssignment] {
            return inner.list()
        }
    }

    static func newCachedLenientSkillMixAssignmentStore(_ inner: MemoryLenientSkillMixAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSkillMixAssignmentStore {
        return CachedLenientSkillMixAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient skill mix assignments. Empty fields match all.
    final class LenientSkillMixAssignmentQuery {
        var unit: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSkillMixAssignment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientSkillMixAssignment]) -> [LenientSkillMixAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSkillMixAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSkillMixAssignments(_ store: any LenientSkillMixAssignmentStore, query: LenientSkillMixAssignmentQuery) -> [LenientSkillMixAssignment] {
        return query.apply(store.list())
    }
}
