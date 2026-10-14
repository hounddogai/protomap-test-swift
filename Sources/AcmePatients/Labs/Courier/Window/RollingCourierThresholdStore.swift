import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling courier thresholds by code.
    protocol RollingCourierThresholdStore {
        func find(_ code: String) -> RollingCourierThreshold?
        func save(_ item: RollingCourierThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCourierThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCourierThresholdStore: RollingCourierThresholdStore {
        var items: [String: RollingCourierThreshold]
        var order: [String]

        init(items: [String: RollingCourierThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCourierThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCourierThreshold) {
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

        func list() -> [RollingCourierThreshold] {
            var out: [RollingCourierThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCourierThresholdStore() -> any RollingCourierThresholdStore {
        return MemoryRollingCourierThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCourierThresholdStore: RollingCourierThresholdStore {
        var inner: MemoryRollingCourierThresholdStore
        var cache: TTLCache<RollingCourierThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCourierThresholdStore, cache: TTLCache<RollingCourierThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCourierThreshold? {
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

        func save(_ item: RollingCourierThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCourierThreshold] {
            return inner.list()
        }
    }

    static func newCachedRollingCourierThresholdStore(_ inner: MemoryRollingCourierThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCourierThresholdStore {
        return CachedRollingCourierThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling courier thresholds. Empty fields match all.
    final class RollingCourierThresholdQuery {
        var region: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRate: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCourierThreshold) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingCourierThreshold]) -> [RollingCourierThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCourierThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCourierThresholds(_ store: any RollingCourierThresholdStore, query: RollingCourierThresholdQuery) -> [RollingCourierThreshold] {
        return query.apply(store.list())
    }
}
