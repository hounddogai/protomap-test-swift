import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding thresholds by code.
    protocol RoundingThresholdStore {
        func find(_ code: String) -> RoundingThreshold?
        func save(_ item: RoundingThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingThresholdStore: RoundingThresholdStore {
        var items: [String: RoundingThreshold]
        var order: [String]

        init(items: [String: RoundingThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingThreshold) {
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

        func list() -> [RoundingThreshold] {
            var out: [RoundingThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingThresholdStore() -> any RoundingThresholdStore {
        return MemoryRoundingThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingThresholdStore: RoundingThresholdStore {
        var inner: MemoryRoundingThresholdStore
        var cache: TTLCache<RoundingThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingThresholdStore, cache: TTLCache<RoundingThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingThreshold? {
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

        func save(_ item: RoundingThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingThreshold] {
            return inner.list()
        }
    }

    static func newCachedRoundingThresholdStore(_ inner: MemoryRoundingThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingThresholdStore {
        return CachedRoundingThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding thresholds. Empty fields match all.
    final class RoundingThresholdQuery {
        var category: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRatio: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingThreshold) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [RoundingThreshold]) -> [RoundingThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingThresholds(_ store: any RoundingThresholdStore, query: RoundingThresholdQuery) -> [RoundingThreshold] {
        return query.apply(store.list())
    }
}
