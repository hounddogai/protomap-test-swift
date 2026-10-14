import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance policies by code.
    protocol RemittancePolicyStore {
        func find(_ code: String) -> RemittancePolicy?
        func save(_ item: RemittancePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [RemittancePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittancePolicyStore: RemittancePolicyStore {
        var items: [String: RemittancePolicy]
        var order: [String]

        init(items: [String: RemittancePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittancePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittancePolicy) {
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

        func list() -> [RemittancePolicy] {
            var out: [RemittancePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittancePolicyStore() -> any RemittancePolicyStore {
        return MemoryRemittancePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittancePolicyStore: RemittancePolicyStore {
        var inner: MemoryRemittancePolicyStore
        var cache: TTLCache<RemittancePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittancePolicyStore, cache: TTLCache<RemittancePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittancePolicy? {
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

        func save(_ item: RemittancePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittancePolicy] {
            return inner.list()
        }
    }

    static func newCachedRemittancePolicyStore(_ inner: MemoryRemittancePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittancePolicyStore {
        return CachedRemittancePolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance policies. Empty fields match all.
    final class RemittancePolicyQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittancePolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittancePolicy]) -> [RemittancePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittancePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittancePolicies(_ store: any RemittancePolicyStore, query: RemittancePolicyQuery) -> [RemittancePolicy] {
        return query.apply(store.list())
    }
}
