import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered specimen assignments by code.
    protocol TieredSpecimenAssignmentStore {
        func find(_ code: String) -> TieredSpecimenAssignment?
        func save(_ item: TieredSpecimenAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredSpecimenAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredSpecimenAssignmentStore: TieredSpecimenAssignmentStore {
        var items: [String: TieredSpecimenAssignment]
        var order: [String]

        init(items: [String: TieredSpecimenAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredSpecimenAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredSpecimenAssignment) {
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

        func list() -> [TieredSpecimenAssignment] {
            var out: [TieredSpecimenAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredSpecimenAssignmentStore() -> any TieredSpecimenAssignmentStore {
        return MemoryTieredSpecimenAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredSpecimenAssignmentStore: TieredSpecimenAssignmentStore {
        var inner: MemoryTieredSpecimenAssignmentStore
        var cache: TTLCache<TieredSpecimenAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredSpecimenAssignmentStore, cache: TTLCache<TieredSpecimenAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredSpecimenAssignment? {
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

        func save(_ item: TieredSpecimenAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredSpecimenAssignment] {
            return inner.list()
        }
    }

    static func newCachedTieredSpecimenAssignmentStore(_ inner: MemoryTieredSpecimenAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredSpecimenAssignmentStore {
        return CachedTieredSpecimenAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered specimen assignments. Empty fields match all.
    final class TieredSpecimenAssignmentQuery {
        var facility: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMargin: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredSpecimenAssignment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredSpecimenAssignment]) -> [TieredSpecimenAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredSpecimenAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredSpecimenAssignments(_ store: any TieredSpecimenAssignmentStore, query: TieredSpecimenAssignmentQuery) -> [TieredSpecimenAssignment] {
        return query.apply(store.list())
    }
}
