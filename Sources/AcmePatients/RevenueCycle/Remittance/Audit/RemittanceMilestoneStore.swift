import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance milestones by code.
    protocol RemittanceMilestoneStore {
        func find(_ code: String) -> RemittanceMilestone?
        func save(_ item: RemittanceMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceMilestoneStore: RemittanceMilestoneStore {
        var items: [String: RemittanceMilestone]
        var order: [String]

        init(items: [String: RemittanceMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceMilestone) {
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

        func list() -> [RemittanceMilestone] {
            var out: [RemittanceMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceMilestoneStore() -> any RemittanceMilestoneStore {
        return MemoryRemittanceMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceMilestoneStore: RemittanceMilestoneStore {
        var inner: MemoryRemittanceMilestoneStore
        var cache: TTLCache<RemittanceMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceMilestoneStore, cache: TTLCache<RemittanceMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceMilestone? {
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

        func save(_ item: RemittanceMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceMilestone] {
            return inner.list()
        }
    }

    static func newCachedRemittanceMilestoneStore(_ inner: MemoryRemittanceMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceMilestoneStore {
        return CachedRemittanceMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance milestones. Empty fields match all.
    final class RemittanceMilestoneQuery {
        var country: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceMilestone) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceMilestone]) -> [RemittanceMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceMilestones(_ store: any RemittanceMilestoneStore, query: RemittanceMilestoneQuery) -> [RemittanceMilestone] {
        return query.apply(store.list())
    }
}
