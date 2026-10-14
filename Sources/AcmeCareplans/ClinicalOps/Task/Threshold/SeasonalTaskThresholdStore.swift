import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal task thresholds by code.
    protocol SeasonalTaskThresholdStore {
        func find(_ code: String) -> SeasonalTaskThreshold?
        func save(_ item: SeasonalTaskThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalTaskThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalTaskThresholdStore: SeasonalTaskThresholdStore {
        var items: [String: SeasonalTaskThreshold]
        var order: [String]

        init(items: [String: SeasonalTaskThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalTaskThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalTaskThreshold) {
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

        func list() -> [SeasonalTaskThreshold] {
            var out: [SeasonalTaskThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalTaskThresholdStore() -> any SeasonalTaskThresholdStore {
        return MemorySeasonalTaskThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalTaskThresholdStore: SeasonalTaskThresholdStore {
        var inner: MemorySeasonalTaskThresholdStore
        var cache: TTLCache<SeasonalTaskThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalTaskThresholdStore, cache: TTLCache<SeasonalTaskThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalTaskThreshold? {
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

        func save(_ item: SeasonalTaskThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalTaskThreshold] {
            return inner.list()
        }
    }

    static func newCachedSeasonalTaskThresholdStore(_ inner: MemorySeasonalTaskThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalTaskThresholdStore {
        return CachedSeasonalTaskThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal task thresholds. Empty fields match all.
    final class SeasonalTaskThresholdQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalTaskThreshold) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalTaskThreshold]) -> [SeasonalTaskThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalTaskThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalTaskThresholds(_ store: any SeasonalTaskThresholdStore, query: SeasonalTaskThresholdQuery) -> [SeasonalTaskThreshold] {
        return query.apply(store.list())
    }
}
