import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient slot assignments by code.
    protocol LenientSlotAssignmentStore {
        func find(_ code: String) -> LenientSlotAssignment?
        func save(_ item: LenientSlotAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSlotAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSlotAssignmentStore: LenientSlotAssignmentStore {
        var items: [String: LenientSlotAssignment]
        var order: [String]

        init(items: [String: LenientSlotAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSlotAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSlotAssignment) {
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

        func list() -> [LenientSlotAssignment] {
            var out: [LenientSlotAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSlotAssignmentStore() -> any LenientSlotAssignmentStore {
        return MemoryLenientSlotAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSlotAssignmentStore: LenientSlotAssignmentStore {
        var inner: MemoryLenientSlotAssignmentStore
        var cache: TTLCache<LenientSlotAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSlotAssignmentStore, cache: TTLCache<LenientSlotAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSlotAssignment? {
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

        func save(_ item: LenientSlotAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSlotAssignment] {
            return inner.list()
        }
    }

    static func newCachedLenientSlotAssignmentStore(_ inner: MemoryLenientSlotAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSlotAssignmentStore {
        return CachedLenientSlotAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient slot assignments. Empty fields match all.
    final class LenientSlotAssignmentQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSlotAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [LenientSlotAssignment]) -> [LenientSlotAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSlotAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSlotAssignments(_ store: any LenientSlotAssignmentStore, query: LenientSlotAssignmentQuery) -> [LenientSlotAssignment] {
        return query.apply(store.list())
    }
}
