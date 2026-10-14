import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled assessment policies by code.
    protocol ScheduledAssessmentPolicyStore {
        func find(_ code: String) -> ScheduledAssessmentPolicy?
        func save(_ item: ScheduledAssessmentPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAssessmentPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAssessmentPolicyStore: ScheduledAssessmentPolicyStore {
        var items: [String: ScheduledAssessmentPolicy]
        var order: [String]

        init(items: [String: ScheduledAssessmentPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAssessmentPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAssessmentPolicy) {
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

        func list() -> [ScheduledAssessmentPolicy] {
            var out: [ScheduledAssessmentPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAssessmentPolicyStore() -> any ScheduledAssessmentPolicyStore {
        return MemoryScheduledAssessmentPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAssessmentPolicyStore: ScheduledAssessmentPolicyStore {
        var inner: MemoryScheduledAssessmentPolicyStore
        var cache: TTLCache<ScheduledAssessmentPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAssessmentPolicyStore, cache: TTLCache<ScheduledAssessmentPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAssessmentPolicy? {
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

        func save(_ item: ScheduledAssessmentPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAssessmentPolicy] {
            return inner.list()
        }
    }

    static func newCachedScheduledAssessmentPolicyStore(_ inner: MemoryScheduledAssessmentPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAssessmentPolicyStore {
        return CachedScheduledAssessmentPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled assessment policies. Empty fields match all.
    final class ScheduledAssessmentPolicyQuery {
        var locale: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minPriority: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAssessmentPolicy) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledAssessmentPolicy]) -> [ScheduledAssessmentPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAssessmentPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAssessmentPolicies(_ store: any ScheduledAssessmentPolicyStore, query: ScheduledAssessmentPolicyQuery) -> [ScheduledAssessmentPolicy] {
        return query.apply(store.list())
    }
}
