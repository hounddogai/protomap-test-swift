import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted goal digests by code.
    protocol WeightedGoalDigestStore {
        func find(_ code: String) -> WeightedGoalDigest?
        func save(_ item: WeightedGoalDigest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedGoalDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedGoalDigestStore: WeightedGoalDigestStore {
        var items: [String: WeightedGoalDigest]
        var order: [String]

        init(items: [String: WeightedGoalDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedGoalDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedGoalDigest) {
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

        func list() -> [WeightedGoalDigest] {
            var out: [WeightedGoalDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedGoalDigestStore() -> any WeightedGoalDigestStore {
        return MemoryWeightedGoalDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedGoalDigestStore: WeightedGoalDigestStore {
        var inner: MemoryWeightedGoalDigestStore
        var cache: TTLCache<WeightedGoalDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedGoalDigestStore, cache: TTLCache<WeightedGoalDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedGoalDigest? {
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

        func save(_ item: WeightedGoalDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedGoalDigest] {
            return inner.list()
        }
    }

    static func newCachedWeightedGoalDigestStore(_ inner: MemoryWeightedGoalDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedGoalDigestStore {
        return CachedWeightedGoalDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted goal digests. Empty fields match all.
    final class WeightedGoalDigestQuery {
        var source: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedGoalDigest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedGoalDigest]) -> [WeightedGoalDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedGoalDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedGoalDigests(_ store: any WeightedGoalDigestStore, query: WeightedGoalDigestQuery) -> [WeightedGoalDigest] {
        return query.apply(store.list())
    }
}
