import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool assignments by code.
    protocol FloatPoolAssignmentStore {
        func find(_ code: String) -> FloatPoolAssignment?
        func save(_ item: FloatPoolAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolAssignmentStore: FloatPoolAssignmentStore {
        var items: [String: FloatPoolAssignment]
        var order: [String]

        init(items: [String: FloatPoolAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolAssignment) {
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

        func list() -> [FloatPoolAssignment] {
            var out: [FloatPoolAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolAssignmentStore() -> any FloatPoolAssignmentStore {
        return MemoryFloatPoolAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolAssignmentStore: FloatPoolAssignmentStore {
        var inner: MemoryFloatPoolAssignmentStore
        var cache: TTLCache<FloatPoolAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolAssignmentStore, cache: TTLCache<FloatPoolAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolAssignment? {
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

        func save(_ item: FloatPoolAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolAssignment] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolAssignmentStore(_ inner: MemoryFloatPoolAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolAssignmentStore {
        return CachedFloatPoolAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool assignments. Empty fields match all.
    final class FloatPoolAssignmentQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolAssignment]) -> [FloatPoolAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolAssignments(_ store: any FloatPoolAssignmentStore, query: FloatPoolAssignmentQuery) -> [FloatPoolAssignment] {
        return query.apply(store.list())
    }
}
