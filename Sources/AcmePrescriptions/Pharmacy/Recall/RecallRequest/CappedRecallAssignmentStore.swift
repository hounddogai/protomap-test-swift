import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped recall assignments by code.
    protocol CappedRecallAssignmentStore {
        func find(_ code: String) -> CappedRecallAssignment?
        func save(_ item: CappedRecallAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRecallAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRecallAssignmentStore: CappedRecallAssignmentStore {
        var items: [String: CappedRecallAssignment]
        var order: [String]

        init(items: [String: CappedRecallAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRecallAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRecallAssignment) {
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

        func list() -> [CappedRecallAssignment] {
            var out: [CappedRecallAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRecallAssignmentStore() -> any CappedRecallAssignmentStore {
        return MemoryCappedRecallAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRecallAssignmentStore: CappedRecallAssignmentStore {
        var inner: MemoryCappedRecallAssignmentStore
        var cache: TTLCache<CappedRecallAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRecallAssignmentStore, cache: TTLCache<CappedRecallAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRecallAssignment? {
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

        func save(_ item: CappedRecallAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRecallAssignment] {
            return inner.list()
        }
    }

    static func newCachedCappedRecallAssignmentStore(_ inner: MemoryCappedRecallAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRecallAssignmentStore {
        return CachedCappedRecallAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped recall assignments. Empty fields match all.
    final class CappedRecallAssignmentQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRecallAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRecallAssignment]) -> [CappedRecallAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRecallAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRecallAssignments(_ store: any CappedRecallAssignmentStore, query: CappedRecallAssignmentQuery) -> [CappedRecallAssignment] {
        return query.apply(store.list())
    }
}
