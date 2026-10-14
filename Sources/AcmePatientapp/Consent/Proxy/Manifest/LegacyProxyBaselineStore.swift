import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy proxy baselines by code.
    protocol LegacyProxyBaselineStore {
        func find(_ code: String) -> LegacyProxyBaseline?
        func save(_ item: LegacyProxyBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyProxyBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyProxyBaselineStore: LegacyProxyBaselineStore {
        var items: [String: LegacyProxyBaseline]
        var order: [String]

        init(items: [String: LegacyProxyBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyProxyBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyProxyBaseline) {
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

        func list() -> [LegacyProxyBaseline] {
            var out: [LegacyProxyBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyProxyBaselineStore() -> any LegacyProxyBaselineStore {
        return MemoryLegacyProxyBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyProxyBaselineStore: LegacyProxyBaselineStore {
        var inner: MemoryLegacyProxyBaselineStore
        var cache: TTLCache<LegacyProxyBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyProxyBaselineStore, cache: TTLCache<LegacyProxyBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyProxyBaseline? {
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

        func save(_ item: LegacyProxyBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyProxyBaseline] {
            return inner.list()
        }
    }

    static func newCachedLegacyProxyBaselineStore(_ inner: MemoryLegacyProxyBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyProxyBaselineStore {
        return CachedLegacyProxyBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy proxy baselines. Empty fields match all.
    final class LegacyProxyBaselineQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyProxyBaseline) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [LegacyProxyBaseline]) -> [LegacyProxyBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyProxyBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyProxyBaselines(_ store: any LegacyProxyBaselineStore, query: LegacyProxyBaselineQuery) -> [LegacyProxyBaseline] {
        return query.apply(store.list())
    }
}
