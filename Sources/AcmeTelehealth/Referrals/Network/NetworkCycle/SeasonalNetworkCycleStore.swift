import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal network cycles by code.
    protocol SeasonalNetworkCycleStore {
        func find(_ code: String) -> SeasonalNetworkCycle?
        func save(_ item: SeasonalNetworkCycle)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalNetworkCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalNetworkCycleStore: SeasonalNetworkCycleStore {
        var items: [String: SeasonalNetworkCycle]
        var order: [String]

        init(items: [String: SeasonalNetworkCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalNetworkCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalNetworkCycle) {
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

        func list() -> [SeasonalNetworkCycle] {
            var out: [SeasonalNetworkCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalNetworkCycleStore() -> any SeasonalNetworkCycleStore {
        return MemorySeasonalNetworkCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalNetworkCycleStore: SeasonalNetworkCycleStore {
        var inner: MemorySeasonalNetworkCycleStore
        var cache: TTLCache<SeasonalNetworkCycle>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalNetworkCycleStore, cache: TTLCache<SeasonalNetworkCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalNetworkCycle? {
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

        func save(_ item: SeasonalNetworkCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalNetworkCycle] {
            return inner.list()
        }
    }

    static func newCachedSeasonalNetworkCycleStore(_ inner: MemorySeasonalNetworkCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalNetworkCycleStore {
        return CachedSeasonalNetworkCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal network cycles. Empty fields match all.
    final class SeasonalNetworkCycleQuery {
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

        func matches(_ item: SeasonalNetworkCycle) -> Bool {
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

        func apply(_ items: [SeasonalNetworkCycle]) -> [SeasonalNetworkCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalNetworkCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalNetworkCycles(_ store: any SeasonalNetworkCycleStore, query: SeasonalNetworkCycleQuery) -> [SeasonalNetworkCycle] {
        return query.apply(store.list())
    }
}
