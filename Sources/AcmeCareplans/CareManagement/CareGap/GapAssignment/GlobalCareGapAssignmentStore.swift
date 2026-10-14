import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global care gap assignments by code.
    protocol GlobalCareGapAssignmentStore {
        func find(_ code: String) -> GlobalCareGapAssignment?
        func save(_ item: GlobalCareGapAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCareGapAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCareGapAssignmentStore: GlobalCareGapAssignmentStore {
        var items: [String: GlobalCareGapAssignment]
        var order: [String]

        init(items: [String: GlobalCareGapAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCareGapAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCareGapAssignment) {
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

        func list() -> [GlobalCareGapAssignment] {
            var out: [GlobalCareGapAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCareGapAssignmentStore() -> any GlobalCareGapAssignmentStore {
        return MemoryGlobalCareGapAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCareGapAssignmentStore: GlobalCareGapAssignmentStore {
        var inner: MemoryGlobalCareGapAssignmentStore
        var cache: TTLCache<GlobalCareGapAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCareGapAssignmentStore, cache: TTLCache<GlobalCareGapAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCareGapAssignment? {
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

        func save(_ item: GlobalCareGapAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCareGapAssignment] {
            return inner.list()
        }
    }

    static func newCachedGlobalCareGapAssignmentStore(_ inner: MemoryGlobalCareGapAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCareGapAssignmentStore {
        return CachedGlobalCareGapAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global care gap assignments. Empty fields match all.
    final class GlobalCareGapAssignmentQuery {
        var unit: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCareGapAssignment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCareGapAssignment]) -> [GlobalCareGapAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCareGapAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCareGapAssignments(_ store: any GlobalCareGapAssignmentStore, query: GlobalCareGapAssignmentQuery) -> [GlobalCareGapAssignment] {
        return query.apply(store.list())
    }
}
