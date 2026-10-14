import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score assignments by code.
    protocol RiskScoreAssignmentStore {
        func find(_ code: String) -> RiskScoreAssignment?
        func save(_ item: RiskScoreAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreAssignmentStore: RiskScoreAssignmentStore {
        var items: [String: RiskScoreAssignment]
        var order: [String]

        init(items: [String: RiskScoreAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreAssignment) {
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

        func list() -> [RiskScoreAssignment] {
            var out: [RiskScoreAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreAssignmentStore() -> any RiskScoreAssignmentStore {
        return MemoryRiskScoreAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreAssignmentStore: RiskScoreAssignmentStore {
        var inner: MemoryRiskScoreAssignmentStore
        var cache: TTLCache<RiskScoreAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreAssignmentStore, cache: TTLCache<RiskScoreAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreAssignment? {
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

        func save(_ item: RiskScoreAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreAssignment] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreAssignmentStore(_ inner: MemoryRiskScoreAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreAssignmentStore {
        return CachedRiskScoreAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score assignments. Empty fields match all.
    final class RiskScoreAssignmentQuery {
        var locale: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRetries: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreAssignment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreAssignment]) -> [RiskScoreAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreAssignments(_ store: any RiskScoreAssignmentStore, query: RiskScoreAssignmentQuery) -> [RiskScoreAssignment] {
        return query.apply(store.list())
    }
}
