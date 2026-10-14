import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global risk score tiers by code.
    protocol GlobalRiskScoreTierStore {
        func find(_ code: String) -> GlobalRiskScoreTier?
        func save(_ item: GlobalRiskScoreTier)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRiskScoreTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRiskScoreTierStore: GlobalRiskScoreTierStore {
        var items: [String: GlobalRiskScoreTier]
        var order: [String]

        init(items: [String: GlobalRiskScoreTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRiskScoreTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRiskScoreTier) {
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

        func list() -> [GlobalRiskScoreTier] {
            var out: [GlobalRiskScoreTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRiskScoreTierStore() -> any GlobalRiskScoreTierStore {
        return MemoryGlobalRiskScoreTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRiskScoreTierStore: GlobalRiskScoreTierStore {
        var inner: MemoryGlobalRiskScoreTierStore
        var cache: TTLCache<GlobalRiskScoreTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRiskScoreTierStore, cache: TTLCache<GlobalRiskScoreTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRiskScoreTier? {
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

        func save(_ item: GlobalRiskScoreTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRiskScoreTier] {
            return inner.list()
        }
    }

    static func newCachedGlobalRiskScoreTierStore(_ inner: MemoryGlobalRiskScoreTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRiskScoreTierStore {
        return CachedGlobalRiskScoreTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global risk score tiers. Empty fields match all.
    final class GlobalRiskScoreTierQuery {
        var country: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minAmount: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRiskScoreTier) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [GlobalRiskScoreTier]) -> [GlobalRiskScoreTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRiskScoreTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRiskScoreTiers(_ store: any GlobalRiskScoreTierStore, query: GlobalRiskScoreTierQuery) -> [GlobalRiskScoreTier] {
        return query.apply(store.list())
    }
}
