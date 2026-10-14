import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback consent form policies by code.
    protocol FallbackConsentFormPolicyStore {
        func find(_ code: String) -> FallbackConsentFormPolicy?
        func save(_ item: FallbackConsentFormPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackConsentFormPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackConsentFormPolicyStore: FallbackConsentFormPolicyStore {
        var items: [String: FallbackConsentFormPolicy]
        var order: [String]

        init(items: [String: FallbackConsentFormPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackConsentFormPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackConsentFormPolicy) {
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

        func list() -> [FallbackConsentFormPolicy] {
            var out: [FallbackConsentFormPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackConsentFormPolicyStore() -> any FallbackConsentFormPolicyStore {
        return MemoryFallbackConsentFormPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackConsentFormPolicyStore: FallbackConsentFormPolicyStore {
        var inner: MemoryFallbackConsentFormPolicyStore
        var cache: TTLCache<FallbackConsentFormPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackConsentFormPolicyStore, cache: TTLCache<FallbackConsentFormPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackConsentFormPolicy? {
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

        func save(_ item: FallbackConsentFormPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackConsentFormPolicy] {
            return inner.list()
        }
    }

    static func newCachedFallbackConsentFormPolicyStore(_ inner: MemoryFallbackConsentFormPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackConsentFormPolicyStore {
        return CachedFallbackConsentFormPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback consent form policies. Empty fields match all.
    final class FallbackConsentFormPolicyQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackConsentFormPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackConsentFormPolicy]) -> [FallbackConsentFormPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackConsentFormPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackConsentFormPolicies(_ store: any FallbackConsentFormPolicyStore, query: FallbackConsentFormPolicyQuery) -> [FallbackConsentFormPolicy] {
        return query.apply(store.list())
    }
}
