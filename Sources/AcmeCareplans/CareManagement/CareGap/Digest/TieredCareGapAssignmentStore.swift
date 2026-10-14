import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered care gap assignments by code.
    protocol TieredCareGapAssignmentStore {
        func find(_ code: String) -> TieredCareGapAssignment?
        func save(_ item: TieredCareGapAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareGapAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareGapAssignmentStore: TieredCareGapAssignmentStore {
        var items: [String: TieredCareGapAssignment]
        var order: [String]

        init(items: [String: TieredCareGapAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareGapAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareGapAssignment) {
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

        func list() -> [TieredCareGapAssignment] {
            var out: [TieredCareGapAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareGapAssignmentStore() -> any TieredCareGapAssignmentStore {
        return MemoryTieredCareGapAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareGapAssignmentStore: TieredCareGapAssignmentStore {
        var inner: MemoryTieredCareGapAssignmentStore
        var cache: TTLCache<TieredCareGapAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareGapAssignmentStore, cache: TTLCache<TieredCareGapAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareGapAssignment? {
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

        func save(_ item: TieredCareGapAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareGapAssignment] {
            return inner.list()
        }
    }

    static func newCachedTieredCareGapAssignmentStore(_ inner: MemoryTieredCareGapAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareGapAssignmentStore {
        return CachedTieredCareGapAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care gap assignments. Empty fields match all.
    final class TieredCareGapAssignmentQuery {
        var category: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minBudget: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareGapAssignment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCareGapAssignment]) -> [TieredCareGapAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareGapAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareGapAssignments(_ store: any TieredCareGapAssignmentStore, query: TieredCareGapAssignmentQuery) -> [TieredCareGapAssignment] {
        return query.apply(store.list())
    }
}
