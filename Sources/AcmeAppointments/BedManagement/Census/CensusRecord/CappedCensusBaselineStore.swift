import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped census baselines by code.
    protocol CappedCensusBaselineStore {
        func find(_ code: String) -> CappedCensusBaseline?
        func save(_ item: CappedCensusBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCensusBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCensusBaselineStore: CappedCensusBaselineStore {
        var items: [String: CappedCensusBaseline]
        var order: [String]

        init(items: [String: CappedCensusBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCensusBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCensusBaseline) {
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

        func list() -> [CappedCensusBaseline] {
            var out: [CappedCensusBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCensusBaselineStore() -> any CappedCensusBaselineStore {
        return MemoryCappedCensusBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCensusBaselineStore: CappedCensusBaselineStore {
        var inner: MemoryCappedCensusBaselineStore
        var cache: TTLCache<CappedCensusBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCensusBaselineStore, cache: TTLCache<CappedCensusBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCensusBaseline? {
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

        func save(_ item: CappedCensusBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCensusBaseline] {
            return inner.list()
        }
    }

    static func newCachedCappedCensusBaselineStore(_ inner: MemoryCappedCensusBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCensusBaselineStore {
        return CachedCappedCensusBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped census baselines. Empty fields match all.
    final class CappedCensusBaselineQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCensusBaseline) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCensusBaseline]) -> [CappedCensusBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCensusBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCensusBaselines(_ store: any CappedCensusBaselineStore, query: CappedCensusBaselineQuery) -> [CappedCensusBaseline] {
        return query.apply(store.list())
    }
}
