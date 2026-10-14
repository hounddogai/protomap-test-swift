import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling witness assignments by code.
    protocol RollingWitnessAssignmentStore {
        func find(_ code: String) -> RollingWitnessAssignment?
        func save(_ item: RollingWitnessAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingWitnessAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingWitnessAssignmentStore: RollingWitnessAssignmentStore {
        var items: [String: RollingWitnessAssignment]
        var order: [String]

        init(items: [String: RollingWitnessAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingWitnessAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingWitnessAssignment) {
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

        func list() -> [RollingWitnessAssignment] {
            var out: [RollingWitnessAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingWitnessAssignmentStore() -> any RollingWitnessAssignmentStore {
        return MemoryRollingWitnessAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingWitnessAssignmentStore: RollingWitnessAssignmentStore {
        var inner: MemoryRollingWitnessAssignmentStore
        var cache: TTLCache<RollingWitnessAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingWitnessAssignmentStore, cache: TTLCache<RollingWitnessAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingWitnessAssignment? {
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

        func save(_ item: RollingWitnessAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingWitnessAssignment] {
            return inner.list()
        }
    }

    static func newCachedRollingWitnessAssignmentStore(_ inner: MemoryRollingWitnessAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingWitnessAssignmentStore {
        return CachedRollingWitnessAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling witness assignments. Empty fields match all.
    final class RollingWitnessAssignmentQuery {
        var locale: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingWitnessAssignment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingWitnessAssignment]) -> [RollingWitnessAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingWitnessAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingWitnessAssignments(_ store: any RollingWitnessAssignmentStore, query: RollingWitnessAssignmentQuery) -> [RollingWitnessAssignment] {
        return query.apply(store.list())
    }
}
