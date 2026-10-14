import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive reference range assignments by code.
    protocol AdaptiveReferenceRangeAssignmentStore {
        func find(_ code: String) -> AdaptiveReferenceRangeAssignment?
        func save(_ item: AdaptiveReferenceRangeAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveReferenceRangeAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveReferenceRangeAssignmentStore: AdaptiveReferenceRangeAssignmentStore {
        var items: [String: AdaptiveReferenceRangeAssignment]
        var order: [String]

        init(items: [String: AdaptiveReferenceRangeAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveReferenceRangeAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveReferenceRangeAssignment) {
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

        func list() -> [AdaptiveReferenceRangeAssignment] {
            var out: [AdaptiveReferenceRangeAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveReferenceRangeAssignmentStore() -> any AdaptiveReferenceRangeAssignmentStore {
        return MemoryAdaptiveReferenceRangeAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveReferenceRangeAssignmentStore: AdaptiveReferenceRangeAssignmentStore {
        var inner: MemoryAdaptiveReferenceRangeAssignmentStore
        var cache: TTLCache<AdaptiveReferenceRangeAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveReferenceRangeAssignmentStore, cache: TTLCache<AdaptiveReferenceRangeAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveReferenceRangeAssignment? {
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

        func save(_ item: AdaptiveReferenceRangeAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveReferenceRangeAssignment] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveReferenceRangeAssignmentStore(_ inner: MemoryAdaptiveReferenceRangeAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveReferenceRangeAssignmentStore {
        return CachedAdaptiveReferenceRangeAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive reference range assignments. Empty fields match all.
    final class AdaptiveReferenceRangeAssignmentQuery {
        var facility: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveReferenceRangeAssignment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveReferenceRangeAssignment]) -> [AdaptiveReferenceRangeAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveReferenceRangeAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveReferenceRangeAssignments(_ store: any AdaptiveReferenceRangeAssignmentStore, query: AdaptiveReferenceRangeAssignmentQuery) -> [AdaptiveReferenceRangeAssignment] {
        return query.apply(store.list())
    }
}
