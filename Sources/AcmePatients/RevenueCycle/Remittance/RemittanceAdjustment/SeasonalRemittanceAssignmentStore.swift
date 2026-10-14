import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal remittance assignments by code.
    protocol SeasonalRemittanceAssignmentStore {
        func find(_ code: String) -> SeasonalRemittanceAssignment?
        func save(_ item: SeasonalRemittanceAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRemittanceAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRemittanceAssignmentStore: SeasonalRemittanceAssignmentStore {
        var items: [String: SeasonalRemittanceAssignment]
        var order: [String]

        init(items: [String: SeasonalRemittanceAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRemittanceAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRemittanceAssignment) {
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

        func list() -> [SeasonalRemittanceAssignment] {
            var out: [SeasonalRemittanceAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRemittanceAssignmentStore() -> any SeasonalRemittanceAssignmentStore {
        return MemorySeasonalRemittanceAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRemittanceAssignmentStore: SeasonalRemittanceAssignmentStore {
        var inner: MemorySeasonalRemittanceAssignmentStore
        var cache: TTLCache<SeasonalRemittanceAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRemittanceAssignmentStore, cache: TTLCache<SeasonalRemittanceAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRemittanceAssignment? {
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

        func save(_ item: SeasonalRemittanceAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRemittanceAssignment] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRemittanceAssignmentStore(_ inner: MemorySeasonalRemittanceAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRemittanceAssignmentStore {
        return CachedSeasonalRemittanceAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal remittance assignments. Empty fields match all.
    final class SeasonalRemittanceAssignmentQuery {
        var segment: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minBudget: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRemittanceAssignment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [SeasonalRemittanceAssignment]) -> [SeasonalRemittanceAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRemittanceAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRemittanceAssignments(_ store: any SeasonalRemittanceAssignmentStore, query: SeasonalRemittanceAssignmentQuery) -> [SeasonalRemittanceAssignment] {
        return query.apply(store.list())
    }
}
