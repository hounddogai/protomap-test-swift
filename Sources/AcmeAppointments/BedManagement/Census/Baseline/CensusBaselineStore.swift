import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census baselines by code.
    protocol CensusBaselineStore {
        func find(_ code: String) -> CensusBaseline?
        func save(_ item: CensusBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [CensusBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusBaselineStore: CensusBaselineStore {
        var items: [String: CensusBaseline]
        var order: [String]

        init(items: [String: CensusBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusBaseline) {
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

        func list() -> [CensusBaseline] {
            var out: [CensusBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusBaselineStore() -> any CensusBaselineStore {
        return MemoryCensusBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusBaselineStore: CensusBaselineStore {
        var inner: MemoryCensusBaselineStore
        var cache: TTLCache<CensusBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusBaselineStore, cache: TTLCache<CensusBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusBaseline? {
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

        func save(_ item: CensusBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusBaseline] {
            return inner.list()
        }
    }

    static func newCachedCensusBaselineStore(_ inner: MemoryCensusBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusBaselineStore {
        return CachedCensusBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census baselines. Empty fields match all.
    final class CensusBaselineQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusBaseline]) -> [CensusBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusBaselines(_ store: any CensusBaselineStore, query: CensusBaselineQuery) -> [CensusBaseline] {
        return query.apply(store.list())
    }
}
