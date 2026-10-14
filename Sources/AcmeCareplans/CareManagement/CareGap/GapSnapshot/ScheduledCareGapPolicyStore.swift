import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled care gap policies by code.
    protocol ScheduledCareGapPolicyStore {
        func find(_ code: String) -> ScheduledCareGapPolicy?
        func save(_ item: ScheduledCareGapPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareGapPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareGapPolicyStore: ScheduledCareGapPolicyStore {
        var items: [String: ScheduledCareGapPolicy]
        var order: [String]

        init(items: [String: ScheduledCareGapPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareGapPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareGapPolicy) {
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

        func list() -> [ScheduledCareGapPolicy] {
            var out: [ScheduledCareGapPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareGapPolicyStore() -> any ScheduledCareGapPolicyStore {
        return MemoryScheduledCareGapPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareGapPolicyStore: ScheduledCareGapPolicyStore {
        var inner: MemoryScheduledCareGapPolicyStore
        var cache: TTLCache<ScheduledCareGapPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareGapPolicyStore, cache: TTLCache<ScheduledCareGapPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareGapPolicy? {
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

        func save(_ item: ScheduledCareGapPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareGapPolicy] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareGapPolicyStore(_ inner: MemoryScheduledCareGapPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareGapPolicyStore {
        return CachedScheduledCareGapPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care gap policies. Empty fields match all.
    final class ScheduledCareGapPolicyQuery {
        var source: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareGapPolicy) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCareGapPolicy]) -> [ScheduledCareGapPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareGapPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareGapPolicies(_ store: any ScheduledCareGapPolicyStore, query: ScheduledCareGapPolicyQuery) -> [ScheduledCareGapPolicy] {
        return query.apply(store.list())
    }
}
