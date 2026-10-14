import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient read assignments by code.
    protocol LenientReadAssignmentStore {
        func find(_ code: String) -> LenientReadAssignment?
        func save(_ item: LenientReadAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReadAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReadAssignmentStore: LenientReadAssignmentStore {
        var items: [String: LenientReadAssignment]
        var order: [String]

        init(items: [String: LenientReadAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReadAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReadAssignment) {
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

        func list() -> [LenientReadAssignment] {
            var out: [LenientReadAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReadAssignmentStore() -> any LenientReadAssignmentStore {
        return MemoryLenientReadAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReadAssignmentStore: LenientReadAssignmentStore {
        var inner: MemoryLenientReadAssignmentStore
        var cache: TTLCache<LenientReadAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReadAssignmentStore, cache: TTLCache<LenientReadAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReadAssignment? {
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

        func save(_ item: LenientReadAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReadAssignment] {
            return inner.list()
        }
    }

    static func newCachedLenientReadAssignmentStore(_ inner: MemoryLenientReadAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReadAssignmentStore {
        return CachedLenientReadAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient read assignments. Empty fields match all.
    final class LenientReadAssignmentQuery {
        var source: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReadAssignment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientReadAssignment]) -> [LenientReadAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReadAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReadAssignments(_ store: any LenientReadAssignmentStore, query: LenientReadAssignmentQuery) -> [LenientReadAssignment] {
        return query.apply(store.list())
    }
}
