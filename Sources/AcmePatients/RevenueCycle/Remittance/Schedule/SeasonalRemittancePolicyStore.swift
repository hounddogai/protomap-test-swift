import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal remittance policies by code.
    protocol SeasonalRemittancePolicyStore {
        func find(_ code: String) -> SeasonalRemittancePolicy?
        func save(_ item: SeasonalRemittancePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRemittancePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRemittancePolicyStore: SeasonalRemittancePolicyStore {
        var items: [String: SeasonalRemittancePolicy]
        var order: [String]

        init(items: [String: SeasonalRemittancePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRemittancePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRemittancePolicy) {
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

        func list() -> [SeasonalRemittancePolicy] {
            var out: [SeasonalRemittancePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRemittancePolicyStore() -> any SeasonalRemittancePolicyStore {
        return MemorySeasonalRemittancePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRemittancePolicyStore: SeasonalRemittancePolicyStore {
        var inner: MemorySeasonalRemittancePolicyStore
        var cache: TTLCache<SeasonalRemittancePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRemittancePolicyStore, cache: TTLCache<SeasonalRemittancePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRemittancePolicy? {
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

        func save(_ item: SeasonalRemittancePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRemittancePolicy] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRemittancePolicyStore(_ inner: MemorySeasonalRemittancePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRemittancePolicyStore {
        return CachedSeasonalRemittancePolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal remittance policies. Empty fields match all.
    final class SeasonalRemittancePolicyQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRemittancePolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalRemittancePolicy]) -> [SeasonalRemittancePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRemittancePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRemittancePolicies(_ store: any SeasonalRemittancePolicyStore, query: SeasonalRemittancePolicyQuery) -> [SeasonalRemittancePolicy] {
        return query.apply(store.list())
    }
}
