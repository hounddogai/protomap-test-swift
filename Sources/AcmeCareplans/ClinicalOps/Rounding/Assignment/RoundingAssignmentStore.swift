import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding assignments by code.
    protocol RoundingAssignmentStore {
        func find(_ code: String) -> RoundingAssignment?
        func save(_ item: RoundingAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingAssignmentStore: RoundingAssignmentStore {
        var items: [String: RoundingAssignment]
        var order: [String]

        init(items: [String: RoundingAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingAssignment) {
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

        func list() -> [RoundingAssignment] {
            var out: [RoundingAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingAssignmentStore() -> any RoundingAssignmentStore {
        return MemoryRoundingAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingAssignmentStore: RoundingAssignmentStore {
        var inner: MemoryRoundingAssignmentStore
        var cache: TTLCache<RoundingAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingAssignmentStore, cache: TTLCache<RoundingAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingAssignment? {
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

        func save(_ item: RoundingAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingAssignment] {
            return inner.list()
        }
    }

    static func newCachedRoundingAssignmentStore(_ inner: MemoryRoundingAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingAssignmentStore {
        return CachedRoundingAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding assignments. Empty fields match all.
    final class RoundingAssignmentQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingAssignment]) -> [RoundingAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingAssignments(_ store: any RoundingAssignmentStore, query: RoundingAssignmentQuery) -> [RoundingAssignment] {
        return query.apply(store.list())
    }
}
