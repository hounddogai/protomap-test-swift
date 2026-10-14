import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional proxy baselines by code.
    protocol RegionalProxyBaselineStore {
        func find(_ code: String) -> RegionalProxyBaseline?
        func save(_ item: RegionalProxyBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalProxyBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalProxyBaselineStore: RegionalProxyBaselineStore {
        var items: [String: RegionalProxyBaseline]
        var order: [String]

        init(items: [String: RegionalProxyBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalProxyBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalProxyBaseline) {
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

        func list() -> [RegionalProxyBaseline] {
            var out: [RegionalProxyBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalProxyBaselineStore() -> any RegionalProxyBaselineStore {
        return MemoryRegionalProxyBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalProxyBaselineStore: RegionalProxyBaselineStore {
        var inner: MemoryRegionalProxyBaselineStore
        var cache: TTLCache<RegionalProxyBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalProxyBaselineStore, cache: TTLCache<RegionalProxyBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalProxyBaseline? {
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

        func save(_ item: RegionalProxyBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalProxyBaseline] {
            return inner.list()
        }
    }

    static func newCachedRegionalProxyBaselineStore(_ inner: MemoryRegionalProxyBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalProxyBaselineStore {
        return CachedRegionalProxyBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional proxy baselines. Empty fields match all.
    final class RegionalProxyBaselineQuery {
        var source: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minWeight: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalProxyBaseline) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalProxyBaseline]) -> [RegionalProxyBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalProxyBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalProxyBaselines(_ store: any RegionalProxyBaselineStore, query: RegionalProxyBaselineQuery) -> [RegionalProxyBaseline] {
        return query.apply(store.list())
    }
}
