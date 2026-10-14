import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped formulary milestones by code.
    protocol CappedFormularyMilestoneStore {
        func find(_ code: String) -> CappedFormularyMilestone?
        func save(_ item: CappedFormularyMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [CappedFormularyMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedFormularyMilestoneStore: CappedFormularyMilestoneStore {
        var items: [String: CappedFormularyMilestone]
        var order: [String]

        init(items: [String: CappedFormularyMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedFormularyMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedFormularyMilestone) {
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

        func list() -> [CappedFormularyMilestone] {
            var out: [CappedFormularyMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedFormularyMilestoneStore() -> any CappedFormularyMilestoneStore {
        return MemoryCappedFormularyMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedFormularyMilestoneStore: CappedFormularyMilestoneStore {
        var inner: MemoryCappedFormularyMilestoneStore
        var cache: TTLCache<CappedFormularyMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedFormularyMilestoneStore, cache: TTLCache<CappedFormularyMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedFormularyMilestone? {
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

        func save(_ item: CappedFormularyMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedFormularyMilestone] {
            return inner.list()
        }
    }

    static func newCachedCappedFormularyMilestoneStore(_ inner: MemoryCappedFormularyMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedFormularyMilestoneStore {
        return CachedCappedFormularyMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped formulary milestones. Empty fields match all.
    final class CappedFormularyMilestoneQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedFormularyMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedFormularyMilestone]) -> [CappedFormularyMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedFormularyMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedFormularyMilestones(_ store: any CappedFormularyMilestoneStore, query: CappedFormularyMilestoneQuery) -> [CappedFormularyMilestone] {
        return query.apply(store.list())
    }
}
