import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled assessment digests by code.
    protocol ScheduledAssessmentDigestStore {
        func find(_ code: String) -> ScheduledAssessmentDigest?
        func save(_ item: ScheduledAssessmentDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAssessmentDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAssessmentDigestStore: ScheduledAssessmentDigestStore {
        var items: [String: ScheduledAssessmentDigest]
        var order: [String]

        init(items: [String: ScheduledAssessmentDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAssessmentDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAssessmentDigest) {
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

        func list() -> [ScheduledAssessmentDigest] {
            var out: [ScheduledAssessmentDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAssessmentDigestStore() -> any ScheduledAssessmentDigestStore {
        return MemoryScheduledAssessmentDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAssessmentDigestStore: ScheduledAssessmentDigestStore {
        var inner: MemoryScheduledAssessmentDigestStore
        var cache: TTLCache<ScheduledAssessmentDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAssessmentDigestStore, cache: TTLCache<ScheduledAssessmentDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAssessmentDigest? {
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

        func save(_ item: ScheduledAssessmentDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAssessmentDigest] {
            return inner.list()
        }
    }

    static func newCachedScheduledAssessmentDigestStore(_ inner: MemoryScheduledAssessmentDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAssessmentDigestStore {
        return CachedScheduledAssessmentDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled assessment digests. Empty fields match all.
    final class ScheduledAssessmentDigestQuery {
        var source: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minBudget: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAssessmentDigest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ScheduledAssessmentDigest]) -> [ScheduledAssessmentDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAssessmentDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAssessmentDigests(_ store: any ScheduledAssessmentDigestStore, query: ScheduledAssessmentDigestQuery) -> [ScheduledAssessmentDigest] {
        return query.apply(store.list())
    }
}
