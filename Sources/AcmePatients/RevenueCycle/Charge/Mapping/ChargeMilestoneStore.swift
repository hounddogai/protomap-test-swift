import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge milestones by code.
    protocol ChargeMilestoneStore {
        func find(_ code: String) -> ChargeMilestone?
        func save(_ item: ChargeMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeMilestoneStore: ChargeMilestoneStore {
        var items: [String: ChargeMilestone]
        var order: [String]

        init(items: [String: ChargeMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeMilestone) {
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

        func list() -> [ChargeMilestone] {
            var out: [ChargeMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeMilestoneStore() -> any ChargeMilestoneStore {
        return MemoryChargeMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeMilestoneStore: ChargeMilestoneStore {
        var inner: MemoryChargeMilestoneStore
        var cache: TTLCache<ChargeMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeMilestoneStore, cache: TTLCache<ChargeMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeMilestone? {
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

        func save(_ item: ChargeMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeMilestone] {
            return inner.list()
        }
    }

    static func newCachedChargeMilestoneStore(_ inner: MemoryChargeMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeMilestoneStore {
        return CachedChargeMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge milestones. Empty fields match all.
    final class ChargeMilestoneQuery {
        var ward: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeMilestone) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ChargeMilestone]) -> [ChargeMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeMilestones(_ store: any ChargeMilestoneStore, query: ChargeMilestoneQuery) -> [ChargeMilestone] {
        return query.apply(store.list())
    }
}
