import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal handoff thresholds by code.
    protocol SeasonalHandoffThresholdStore {
        func find(_ code: String) -> SeasonalHandoffThreshold?
        func save(_ item: SeasonalHandoffThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalHandoffThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalHandoffThresholdStore: SeasonalHandoffThresholdStore {
        var items: [String: SeasonalHandoffThreshold]
        var order: [String]

        init(items: [String: SeasonalHandoffThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalHandoffThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalHandoffThreshold) {
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

        func list() -> [SeasonalHandoffThreshold] {
            var out: [SeasonalHandoffThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalHandoffThresholdStore() -> any SeasonalHandoffThresholdStore {
        return MemorySeasonalHandoffThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalHandoffThresholdStore: SeasonalHandoffThresholdStore {
        var inner: MemorySeasonalHandoffThresholdStore
        var cache: TTLCache<SeasonalHandoffThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalHandoffThresholdStore, cache: TTLCache<SeasonalHandoffThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalHandoffThreshold? {
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

        func save(_ item: SeasonalHandoffThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalHandoffThreshold] {
            return inner.list()
        }
    }

    static func newCachedSeasonalHandoffThresholdStore(_ inner: MemorySeasonalHandoffThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalHandoffThresholdStore {
        return CachedSeasonalHandoffThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal handoff thresholds. Empty fields match all.
    final class SeasonalHandoffThresholdQuery {
        var segment: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minRatio: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalHandoffThreshold) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalHandoffThreshold]) -> [SeasonalHandoffThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalHandoffThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalHandoffThresholds(_ store: any SeasonalHandoffThresholdStore, query: SeasonalHandoffThresholdQuery) -> [SeasonalHandoffThreshold] {
        return query.apply(store.list())
    }
}
