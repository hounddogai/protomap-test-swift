import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback care protocol policies by code.
    protocol FallbackCareProtocolPolicyStore {
        func find(_ code: String) -> FallbackCareProtocolPolicy?
        func save(_ item: FallbackCareProtocolPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareProtocolPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareProtocolPolicyStore: FallbackCareProtocolPolicyStore {
        var items: [String: FallbackCareProtocolPolicy]
        var order: [String]

        init(items: [String: FallbackCareProtocolPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareProtocolPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareProtocolPolicy) {
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

        func list() -> [FallbackCareProtocolPolicy] {
            var out: [FallbackCareProtocolPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareProtocolPolicyStore() -> any FallbackCareProtocolPolicyStore {
        return MemoryFallbackCareProtocolPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareProtocolPolicyStore: FallbackCareProtocolPolicyStore {
        var inner: MemoryFallbackCareProtocolPolicyStore
        var cache: TTLCache<FallbackCareProtocolPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareProtocolPolicyStore, cache: TTLCache<FallbackCareProtocolPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareProtocolPolicy? {
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

        func save(_ item: FallbackCareProtocolPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareProtocolPolicy] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareProtocolPolicyStore(_ inner: MemoryFallbackCareProtocolPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareProtocolPolicyStore {
        return CachedFallbackCareProtocolPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care protocol policies. Empty fields match all.
    final class FallbackCareProtocolPolicyQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareProtocolPolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCareProtocolPolicy]) -> [FallbackCareProtocolPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareProtocolPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareProtocolPolicies(_ store: any FallbackCareProtocolPolicyStore, query: FallbackCareProtocolPolicyQuery) -> [FallbackCareProtocolPolicy] {
        return query.apply(store.list())
    }
}
