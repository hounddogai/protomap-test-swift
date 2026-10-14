import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling remittance estimates by code.
    protocol RollingRemittanceEstimateStore {
        func find(_ code: String) -> RollingRemittanceEstimate?
        func save(_ item: RollingRemittanceEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRemittanceEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRemittanceEstimateStore: RollingRemittanceEstimateStore {
        var items: [String: RollingRemittanceEstimate]
        var order: [String]

        init(items: [String: RollingRemittanceEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRemittanceEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRemittanceEstimate) {
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

        func list() -> [RollingRemittanceEstimate] {
            var out: [RollingRemittanceEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRemittanceEstimateStore() -> any RollingRemittanceEstimateStore {
        return MemoryRollingRemittanceEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRemittanceEstimateStore: RollingRemittanceEstimateStore {
        var inner: MemoryRollingRemittanceEstimateStore
        var cache: TTLCache<RollingRemittanceEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRemittanceEstimateStore, cache: TTLCache<RollingRemittanceEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRemittanceEstimate? {
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

        func save(_ item: RollingRemittanceEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRemittanceEstimate] {
            return inner.list()
        }
    }

    static func newCachedRollingRemittanceEstimateStore(_ inner: MemoryRollingRemittanceEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRemittanceEstimateStore {
        return CachedRollingRemittanceEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling remittance estimates. Empty fields match all.
    final class RollingRemittanceEstimateQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRemittanceEstimate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [RollingRemittanceEstimate]) -> [RollingRemittanceEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRemittanceEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRemittanceEstimates(_ store: any RollingRemittanceEstimateStore, query: RollingRemittanceEstimateQuery) -> [RollingRemittanceEstimate] {
        return query.apply(store.list())
    }
}
