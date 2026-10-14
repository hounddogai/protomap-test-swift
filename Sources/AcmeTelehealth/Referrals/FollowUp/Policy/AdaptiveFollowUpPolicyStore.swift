import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive follow up policies by code.
    protocol AdaptiveFollowUpPolicyStore {
        func find(_ code: String) -> AdaptiveFollowUpPolicy?
        func save(_ item: AdaptiveFollowUpPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveFollowUpPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveFollowUpPolicyStore: AdaptiveFollowUpPolicyStore {
        var items: [String: AdaptiveFollowUpPolicy]
        var order: [String]

        init(items: [String: AdaptiveFollowUpPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveFollowUpPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveFollowUpPolicy) {
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

        func list() -> [AdaptiveFollowUpPolicy] {
            var out: [AdaptiveFollowUpPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveFollowUpPolicyStore() -> any AdaptiveFollowUpPolicyStore {
        return MemoryAdaptiveFollowUpPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveFollowUpPolicyStore: AdaptiveFollowUpPolicyStore {
        var inner: MemoryAdaptiveFollowUpPolicyStore
        var cache: TTLCache<AdaptiveFollowUpPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveFollowUpPolicyStore, cache: TTLCache<AdaptiveFollowUpPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveFollowUpPolicy? {
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

        func save(_ item: AdaptiveFollowUpPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveFollowUpPolicy] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveFollowUpPolicyStore(_ inner: MemoryAdaptiveFollowUpPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveFollowUpPolicyStore {
        return CachedAdaptiveFollowUpPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive follow up policies. Empty fields match all.
    final class AdaptiveFollowUpPolicyQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveFollowUpPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveFollowUpPolicy]) -> [AdaptiveFollowUpPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveFollowUpPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveFollowUpPolicies(_ store: any AdaptiveFollowUpPolicyStore, query: AdaptiveFollowUpPolicyQuery) -> [AdaptiveFollowUpPolicy] {
        return query.apply(store.list())
    }
}
