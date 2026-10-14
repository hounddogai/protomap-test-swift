import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary read milestones by code.
    protocol PrimaryReadMilestoneStore {
        func find(_ code: String) -> PrimaryReadMilestone?
        func save(_ item: PrimaryReadMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryReadMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryReadMilestoneStore: PrimaryReadMilestoneStore {
        var items: [String: PrimaryReadMilestone]
        var order: [String]

        init(items: [String: PrimaryReadMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryReadMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryReadMilestone) {
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

        func list() -> [PrimaryReadMilestone] {
            var out: [PrimaryReadMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryReadMilestoneStore() -> any PrimaryReadMilestoneStore {
        return MemoryPrimaryReadMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryReadMilestoneStore: PrimaryReadMilestoneStore {
        var inner: MemoryPrimaryReadMilestoneStore
        var cache: TTLCache<PrimaryReadMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryReadMilestoneStore, cache: TTLCache<PrimaryReadMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryReadMilestone? {
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

        func save(_ item: PrimaryReadMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryReadMilestone] {
            return inner.list()
        }
    }

    static func newCachedPrimaryReadMilestoneStore(_ inner: MemoryPrimaryReadMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryReadMilestoneStore {
        return CachedPrimaryReadMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary read milestones. Empty fields match all.
    final class PrimaryReadMilestoneQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryReadMilestone) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryReadMilestone]) -> [PrimaryReadMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryReadMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryReadMilestones(_ store: any PrimaryReadMilestoneStore, query: PrimaryReadMilestoneQuery) -> [PrimaryReadMilestone] {
        return query.apply(store.list())
    }
}
