import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps lenient care protocol policies by code.
    protocol LenientCareProtocolPolicyStore {
        func find(_ code: String) -> LenientCareProtocolPolicy?
        func save(_ item: LenientCareProtocolPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCareProtocolPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCareProtocolPolicyStore: LenientCareProtocolPolicyStore {
        var items: [String: LenientCareProtocolPolicy]
        var order: [String]

        init(items: [String: LenientCareProtocolPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCareProtocolPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCareProtocolPolicy) {
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

        func list() -> [LenientCareProtocolPolicy] {
            var out: [LenientCareProtocolPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCareProtocolPolicyStore() -> any LenientCareProtocolPolicyStore {
        return MemoryLenientCareProtocolPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCareProtocolPolicyStore: LenientCareProtocolPolicyStore {
        var inner: MemoryLenientCareProtocolPolicyStore
        var cache: TTLCache<LenientCareProtocolPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCareProtocolPolicyStore, cache: TTLCache<LenientCareProtocolPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCareProtocolPolicy? {
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

        func save(_ item: LenientCareProtocolPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCareProtocolPolicy] {
            return inner.list()
        }
    }

    static func newCachedLenientCareProtocolPolicyStore(_ inner: MemoryLenientCareProtocolPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCareProtocolPolicyStore {
        return CachedLenientCareProtocolPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient care protocol policies. Empty fields match all.
    final class LenientCareProtocolPolicyQuery {
        var channel: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRetries: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCareProtocolPolicy) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [LenientCareProtocolPolicy]) -> [LenientCareProtocolPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCareProtocolPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCareProtocolPolicies(_ store: any LenientCareProtocolPolicyStore, query: LenientCareProtocolPolicyQuery) -> [LenientCareProtocolPolicy] {
        return query.apply(store.list())
    }
}
