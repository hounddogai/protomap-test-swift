import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol policies by code.
    protocol CareProtocolPolicyStore {
        func find(_ code: String) -> CareProtocolPolicy?
        func save(_ item: CareProtocolPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolPolicyStore: CareProtocolPolicyStore {
        var items: [String: CareProtocolPolicy]
        var order: [String]

        init(items: [String: CareProtocolPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolPolicy) {
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

        func list() -> [CareProtocolPolicy] {
            var out: [CareProtocolPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolPolicyStore() -> any CareProtocolPolicyStore {
        return MemoryCareProtocolPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolPolicyStore: CareProtocolPolicyStore {
        var inner: MemoryCareProtocolPolicyStore
        var cache: TTLCache<CareProtocolPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolPolicyStore, cache: TTLCache<CareProtocolPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolPolicy? {
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

        func save(_ item: CareProtocolPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolPolicy] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolPolicyStore(_ inner: MemoryCareProtocolPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolPolicyStore {
        return CachedCareProtocolPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol policies. Empty fields match all.
    final class CareProtocolPolicyQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolPolicy]) -> [CareProtocolPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolPolicies(_ store: any CareProtocolPolicyStore, query: CareProtocolPolicyQuery) -> [CareProtocolPolicy] {
        return query.apply(store.list())
    }
}
