import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive result policies by code.
    protocol AdaptiveResultPolicyStore {
        func find(_ code: String) -> AdaptiveResultPolicy?
        func save(_ item: AdaptiveResultPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveResultPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveResultPolicyStore: AdaptiveResultPolicyStore {
        var items: [String: AdaptiveResultPolicy]
        var order: [String]

        init(items: [String: AdaptiveResultPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveResultPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveResultPolicy) {
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

        func list() -> [AdaptiveResultPolicy] {
            var out: [AdaptiveResultPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveResultPolicyStore() -> any AdaptiveResultPolicyStore {
        return MemoryAdaptiveResultPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveResultPolicyStore: AdaptiveResultPolicyStore {
        var inner: MemoryAdaptiveResultPolicyStore
        var cache: TTLCache<AdaptiveResultPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveResultPolicyStore, cache: TTLCache<AdaptiveResultPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveResultPolicy? {
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

        func save(_ item: AdaptiveResultPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveResultPolicy] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveResultPolicyStore(_ inner: MemoryAdaptiveResultPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveResultPolicyStore {
        return CachedAdaptiveResultPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive result policies. Empty fields match all.
    final class AdaptiveResultPolicyQuery {
        var segment: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRetries: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveResultPolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [AdaptiveResultPolicy]) -> [AdaptiveResultPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveResultPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveResultPolicies(_ store: any AdaptiveResultPolicyStore, query: AdaptiveResultPolicyQuery) -> [AdaptiveResultPolicy] {
        return query.apply(store.list())
    }
}
