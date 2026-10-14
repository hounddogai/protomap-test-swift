import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled study policies by code.
    protocol ScheduledStudyPolicyStore {
        func find(_ code: String) -> ScheduledStudyPolicy?
        func save(_ item: ScheduledStudyPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledStudyPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledStudyPolicyStore: ScheduledStudyPolicyStore {
        var items: [String: ScheduledStudyPolicy]
        var order: [String]

        init(items: [String: ScheduledStudyPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledStudyPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledStudyPolicy) {
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

        func list() -> [ScheduledStudyPolicy] {
            var out: [ScheduledStudyPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledStudyPolicyStore() -> any ScheduledStudyPolicyStore {
        return MemoryScheduledStudyPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledStudyPolicyStore: ScheduledStudyPolicyStore {
        var inner: MemoryScheduledStudyPolicyStore
        var cache: TTLCache<ScheduledStudyPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledStudyPolicyStore, cache: TTLCache<ScheduledStudyPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledStudyPolicy? {
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

        func save(_ item: ScheduledStudyPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledStudyPolicy] {
            return inner.list()
        }
    }

    static func newCachedScheduledStudyPolicyStore(_ inner: MemoryScheduledStudyPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledStudyPolicyStore {
        return CachedScheduledStudyPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled study policies. Empty fields match all.
    final class ScheduledStudyPolicyQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledStudyPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledStudyPolicy]) -> [ScheduledStudyPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledStudyPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledStudyPolicies(_ store: any ScheduledStudyPolicyStore, query: ScheduledStudyPolicyQuery) -> [ScheduledStudyPolicy] {
        return query.apply(store.list())
    }
}
