import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped care gap assignments by code.
    protocol CappedCareGapAssignmentStore {
        func find(_ code: String) -> CappedCareGapAssignment?
        func save(_ item: CappedCareGapAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCareGapAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCareGapAssignmentStore: CappedCareGapAssignmentStore {
        var items: [String: CappedCareGapAssignment]
        var order: [String]

        init(items: [String: CappedCareGapAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCareGapAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCareGapAssignment) {
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

        func list() -> [CappedCareGapAssignment] {
            var out: [CappedCareGapAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCareGapAssignmentStore() -> any CappedCareGapAssignmentStore {
        return MemoryCappedCareGapAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCareGapAssignmentStore: CappedCareGapAssignmentStore {
        var inner: MemoryCappedCareGapAssignmentStore
        var cache: TTLCache<CappedCareGapAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCareGapAssignmentStore, cache: TTLCache<CappedCareGapAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCareGapAssignment? {
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

        func save(_ item: CappedCareGapAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCareGapAssignment] {
            return inner.list()
        }
    }

    static func newCachedCappedCareGapAssignmentStore(_ inner: MemoryCappedCareGapAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCareGapAssignmentStore {
        return CachedCappedCareGapAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped care gap assignments. Empty fields match all.
    final class CappedCareGapAssignmentQuery {
        var source: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCareGapAssignment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCareGapAssignment]) -> [CappedCareGapAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCareGapAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCareGapAssignments(_ store: any CappedCareGapAssignmentStore, query: CappedCareGapAssignmentQuery) -> [CappedCareGapAssignment] {
        return query.apply(store.list())
    }
}
