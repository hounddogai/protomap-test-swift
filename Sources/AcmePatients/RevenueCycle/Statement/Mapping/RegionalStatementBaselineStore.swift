import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional statement baselines by code.
    protocol RegionalStatementBaselineStore {
        func find(_ code: String) -> RegionalStatementBaseline?
        func save(_ item: RegionalStatementBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalStatementBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalStatementBaselineStore: RegionalStatementBaselineStore {
        var items: [String: RegionalStatementBaseline]
        var order: [String]

        init(items: [String: RegionalStatementBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalStatementBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalStatementBaseline) {
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

        func list() -> [RegionalStatementBaseline] {
            var out: [RegionalStatementBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalStatementBaselineStore() -> any RegionalStatementBaselineStore {
        return MemoryRegionalStatementBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalStatementBaselineStore: RegionalStatementBaselineStore {
        var inner: MemoryRegionalStatementBaselineStore
        var cache: TTLCache<RegionalStatementBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalStatementBaselineStore, cache: TTLCache<RegionalStatementBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalStatementBaseline? {
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

        func save(_ item: RegionalStatementBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalStatementBaseline] {
            return inner.list()
        }
    }

    static func newCachedRegionalStatementBaselineStore(_ inner: MemoryRegionalStatementBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalStatementBaselineStore {
        return CachedRegionalStatementBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional statement baselines. Empty fields match all.
    final class RegionalStatementBaselineQuery {
        var ward: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCopay: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalStatementBaseline) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalStatementBaseline]) -> [RegionalStatementBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalStatementBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalStatementBaselines(_ store: any RegionalStatementBaselineStore, query: RegionalStatementBaselineQuery) -> [RegionalStatementBaseline] {
        return query.apply(store.list())
    }
}
