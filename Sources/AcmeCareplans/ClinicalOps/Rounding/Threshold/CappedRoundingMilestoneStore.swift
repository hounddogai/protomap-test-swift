import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped rounding milestones by code.
    protocol CappedRoundingMilestoneStore {
        func find(_ code: String) -> CappedRoundingMilestone?
        func save(_ item: CappedRoundingMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRoundingMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRoundingMilestoneStore: CappedRoundingMilestoneStore {
        var items: [String: CappedRoundingMilestone]
        var order: [String]

        init(items: [String: CappedRoundingMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRoundingMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRoundingMilestone) {
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

        func list() -> [CappedRoundingMilestone] {
            var out: [CappedRoundingMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRoundingMilestoneStore() -> any CappedRoundingMilestoneStore {
        return MemoryCappedRoundingMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRoundingMilestoneStore: CappedRoundingMilestoneStore {
        var inner: MemoryCappedRoundingMilestoneStore
        var cache: TTLCache<CappedRoundingMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRoundingMilestoneStore, cache: TTLCache<CappedRoundingMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRoundingMilestone? {
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

        func save(_ item: CappedRoundingMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRoundingMilestone] {
            return inner.list()
        }
    }

    static func newCachedCappedRoundingMilestoneStore(_ inner: MemoryCappedRoundingMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRoundingMilestoneStore {
        return CachedCappedRoundingMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped rounding milestones. Empty fields match all.
    final class CappedRoundingMilestoneQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRoundingMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRoundingMilestone]) -> [CappedRoundingMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRoundingMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRoundingMilestones(_ store: any CappedRoundingMilestoneStore, query: CappedRoundingMilestoneQuery) -> [CappedRoundingMilestone] {
        return query.apply(store.list())
    }
}
