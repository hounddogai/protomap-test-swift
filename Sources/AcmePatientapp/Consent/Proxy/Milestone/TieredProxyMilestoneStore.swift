import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered proxy milestones by code.
    protocol TieredProxyMilestoneStore {
        func find(_ code: String) -> TieredProxyMilestone?
        func save(_ item: TieredProxyMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [TieredProxyMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredProxyMilestoneStore: TieredProxyMilestoneStore {
        var items: [String: TieredProxyMilestone]
        var order: [String]

        init(items: [String: TieredProxyMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredProxyMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredProxyMilestone) {
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

        func list() -> [TieredProxyMilestone] {
            var out: [TieredProxyMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredProxyMilestoneStore() -> any TieredProxyMilestoneStore {
        return MemoryTieredProxyMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredProxyMilestoneStore: TieredProxyMilestoneStore {
        var inner: MemoryTieredProxyMilestoneStore
        var cache: TTLCache<TieredProxyMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredProxyMilestoneStore, cache: TTLCache<TieredProxyMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredProxyMilestone? {
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

        func save(_ item: TieredProxyMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredProxyMilestone] {
            return inner.list()
        }
    }

    static func newCachedTieredProxyMilestoneStore(_ inner: MemoryTieredProxyMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredProxyMilestoneStore {
        return CachedTieredProxyMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered proxy milestones. Empty fields match all.
    final class TieredProxyMilestoneQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredProxyMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [TieredProxyMilestone]) -> [TieredProxyMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredProxyMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredProxyMilestones(_ store: any TieredProxyMilestoneStore, query: TieredProxyMilestoneQuery) -> [TieredProxyMilestone] {
        return query.apply(store.list())
    }
}
