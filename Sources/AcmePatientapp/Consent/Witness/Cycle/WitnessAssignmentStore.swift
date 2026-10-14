import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness assignments by code.
    protocol WitnessAssignmentStore {
        func find(_ code: String) -> WitnessAssignment?
        func save(_ item: WitnessAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessAssignmentStore: WitnessAssignmentStore {
        var items: [String: WitnessAssignment]
        var order: [String]

        init(items: [String: WitnessAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessAssignment) {
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

        func list() -> [WitnessAssignment] {
            var out: [WitnessAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessAssignmentStore() -> any WitnessAssignmentStore {
        return MemoryWitnessAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessAssignmentStore: WitnessAssignmentStore {
        var inner: MemoryWitnessAssignmentStore
        var cache: TTLCache<WitnessAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessAssignmentStore, cache: TTLCache<WitnessAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessAssignment? {
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

        func save(_ item: WitnessAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessAssignment] {
            return inner.list()
        }
    }

    static func newCachedWitnessAssignmentStore(_ inner: MemoryWitnessAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessAssignmentStore {
        return CachedWitnessAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness assignments. Empty fields match all.
    final class WitnessAssignmentQuery {
        var category: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessAssignment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [WitnessAssignment]) -> [WitnessAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessAssignments(_ store: any WitnessAssignmentStore, query: WitnessAssignmentQuery) -> [WitnessAssignment] {
        return query.apply(store.list())
    }
}
