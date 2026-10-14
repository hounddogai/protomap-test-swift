import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan assignments by code.
    protocol AcuityPlanAssignmentStore {
        func find(_ code: String) -> AcuityPlanAssignment?
        func save(_ item: AcuityPlanAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanAssignmentStore: AcuityPlanAssignmentStore {
        var items: [String: AcuityPlanAssignment]
        var order: [String]

        init(items: [String: AcuityPlanAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanAssignment) {
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

        func list() -> [AcuityPlanAssignment] {
            var out: [AcuityPlanAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanAssignmentStore() -> any AcuityPlanAssignmentStore {
        return MemoryAcuityPlanAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanAssignmentStore: AcuityPlanAssignmentStore {
        var inner: MemoryAcuityPlanAssignmentStore
        var cache: TTLCache<AcuityPlanAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanAssignmentStore, cache: TTLCache<AcuityPlanAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanAssignment? {
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

        func save(_ item: AcuityPlanAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanAssignment] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanAssignmentStore(_ inner: MemoryAcuityPlanAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanAssignmentStore {
        return CachedAcuityPlanAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan assignments. Empty fields match all.
    final class AcuityPlanAssignmentQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanAssignment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanAssignment]) -> [AcuityPlanAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanAssignments(_ store: any AcuityPlanAssignmentStore, query: AcuityPlanAssignmentQuery) -> [AcuityPlanAssignment] {
        return query.apply(store.list())
    }
}
