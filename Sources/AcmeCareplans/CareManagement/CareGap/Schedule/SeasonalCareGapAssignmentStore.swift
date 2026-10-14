import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal care gap assignments by code.
    protocol SeasonalCareGapAssignmentStore {
        func find(_ code: String) -> SeasonalCareGapAssignment?
        func save(_ item: SeasonalCareGapAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareGapAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareGapAssignmentStore: SeasonalCareGapAssignmentStore {
        var items: [String: SeasonalCareGapAssignment]
        var order: [String]

        init(items: [String: SeasonalCareGapAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareGapAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareGapAssignment) {
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

        func list() -> [SeasonalCareGapAssignment] {
            var out: [SeasonalCareGapAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareGapAssignmentStore() -> any SeasonalCareGapAssignmentStore {
        return MemorySeasonalCareGapAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareGapAssignmentStore: SeasonalCareGapAssignmentStore {
        var inner: MemorySeasonalCareGapAssignmentStore
        var cache: TTLCache<SeasonalCareGapAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareGapAssignmentStore, cache: TTLCache<SeasonalCareGapAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareGapAssignment? {
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

        func save(_ item: SeasonalCareGapAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareGapAssignment] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareGapAssignmentStore(_ inner: MemorySeasonalCareGapAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareGapAssignmentStore {
        return CachedSeasonalCareGapAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care gap assignments. Empty fields match all.
    final class SeasonalCareGapAssignmentQuery {
        var name: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareGapAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareGapAssignment]) -> [SeasonalCareGapAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareGapAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareGapAssignments(_ store: any SeasonalCareGapAssignmentStore, query: SeasonalCareGapAssignmentQuery) -> [SeasonalCareGapAssignment] {
        return query.apply(store.list())
    }
}
