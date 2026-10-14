import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled float pool policies by code.
    protocol ScheduledFloatPoolPolicyStore {
        func find(_ code: String) -> ScheduledFloatPoolPolicy?
        func save(_ item: ScheduledFloatPoolPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFloatPoolPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFloatPoolPolicyStore: ScheduledFloatPoolPolicyStore {
        var items: [String: ScheduledFloatPoolPolicy]
        var order: [String]

        init(items: [String: ScheduledFloatPoolPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFloatPoolPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFloatPoolPolicy) {
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

        func list() -> [ScheduledFloatPoolPolicy] {
            var out: [ScheduledFloatPoolPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFloatPoolPolicyStore() -> any ScheduledFloatPoolPolicyStore {
        return MemoryScheduledFloatPoolPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFloatPoolPolicyStore: ScheduledFloatPoolPolicyStore {
        var inner: MemoryScheduledFloatPoolPolicyStore
        var cache: TTLCache<ScheduledFloatPoolPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFloatPoolPolicyStore, cache: TTLCache<ScheduledFloatPoolPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFloatPoolPolicy? {
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

        func save(_ item: ScheduledFloatPoolPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFloatPoolPolicy] {
            return inner.list()
        }
    }

    static func newCachedScheduledFloatPoolPolicyStore(_ inner: MemoryScheduledFloatPoolPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFloatPoolPolicyStore {
        return CachedScheduledFloatPoolPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled float pool policies. Empty fields match all.
    final class ScheduledFloatPoolPolicyQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFloatPoolPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFloatPoolPolicy]) -> [ScheduledFloatPoolPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFloatPoolPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFloatPoolPolicies(_ store: any ScheduledFloatPoolPolicyStore, query: ScheduledFloatPoolPolicyQuery) -> [ScheduledFloatPoolPolicy] {
        return query.apply(store.list())
    }
}
