import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps scheduled formulary milestones by code.
    protocol ScheduledFormularyMilestoneStore {
        func find(_ code: String) -> ScheduledFormularyMilestone?
        func save(_ item: ScheduledFormularyMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFormularyMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFormularyMilestoneStore: ScheduledFormularyMilestoneStore {
        var items: [String: ScheduledFormularyMilestone]
        var order: [String]

        init(items: [String: ScheduledFormularyMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFormularyMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFormularyMilestone) {
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

        func list() -> [ScheduledFormularyMilestone] {
            var out: [ScheduledFormularyMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFormularyMilestoneStore() -> any ScheduledFormularyMilestoneStore {
        return MemoryScheduledFormularyMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFormularyMilestoneStore: ScheduledFormularyMilestoneStore {
        var inner: MemoryScheduledFormularyMilestoneStore
        var cache: TTLCache<ScheduledFormularyMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFormularyMilestoneStore, cache: TTLCache<ScheduledFormularyMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFormularyMilestone? {
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

        func save(_ item: ScheduledFormularyMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFormularyMilestone] {
            return inner.list()
        }
    }

    static func newCachedScheduledFormularyMilestoneStore(_ inner: MemoryScheduledFormularyMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFormularyMilestoneStore {
        return CachedScheduledFormularyMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled formulary milestones. Empty fields match all.
    final class ScheduledFormularyMilestoneQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFormularyMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFormularyMilestone]) -> [ScheduledFormularyMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFormularyMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFormularyMilestones(_ store: any ScheduledFormularyMilestoneStore, query: ScheduledFormularyMilestoneQuery) -> [ScheduledFormularyMilestone] {
        return query.apply(store.list())
    }
}
