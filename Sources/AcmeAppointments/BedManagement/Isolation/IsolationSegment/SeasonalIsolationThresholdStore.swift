import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps seasonal isolation thresholds by code.
    protocol SeasonalIsolationThresholdStore {
        func find(_ code: String) -> SeasonalIsolationThreshold?
        func save(_ item: SeasonalIsolationThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalIsolationThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalIsolationThresholdStore: SeasonalIsolationThresholdStore {
        var items: [String: SeasonalIsolationThreshold]
        var order: [String]

        init(items: [String: SeasonalIsolationThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalIsolationThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalIsolationThreshold) {
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

        func list() -> [SeasonalIsolationThreshold] {
            var out: [SeasonalIsolationThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalIsolationThresholdStore() -> any SeasonalIsolationThresholdStore {
        return MemorySeasonalIsolationThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalIsolationThresholdStore: SeasonalIsolationThresholdStore {
        var inner: MemorySeasonalIsolationThresholdStore
        var cache: TTLCache<SeasonalIsolationThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalIsolationThresholdStore, cache: TTLCache<SeasonalIsolationThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalIsolationThreshold? {
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

        func save(_ item: SeasonalIsolationThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalIsolationThreshold] {
            return inner.list()
        }
    }

    static func newCachedSeasonalIsolationThresholdStore(_ inner: MemorySeasonalIsolationThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalIsolationThresholdStore {
        return CachedSeasonalIsolationThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal isolation thresholds. Empty fields match all.
    final class SeasonalIsolationThresholdQuery {
        var country: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalIsolationThreshold) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalIsolationThreshold]) -> [SeasonalIsolationThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalIsolationThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalIsolationThresholds(_ store: any SeasonalIsolationThresholdStore, query: SeasonalIsolationThresholdQuery) -> [SeasonalIsolationThreshold] {
        return query.apply(store.list())
    }
}
