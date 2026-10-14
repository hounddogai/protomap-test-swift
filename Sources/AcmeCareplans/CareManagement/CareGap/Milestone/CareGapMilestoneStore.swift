import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap milestones by code.
    protocol CareGapMilestoneStore {
        func find(_ code: String) -> CareGapMilestone?
        func save(_ item: CareGapMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapMilestoneStore: CareGapMilestoneStore {
        var items: [String: CareGapMilestone]
        var order: [String]

        init(items: [String: CareGapMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapMilestone) {
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

        func list() -> [CareGapMilestone] {
            var out: [CareGapMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapMilestoneStore() -> any CareGapMilestoneStore {
        return MemoryCareGapMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapMilestoneStore: CareGapMilestoneStore {
        var inner: MemoryCareGapMilestoneStore
        var cache: TTLCache<CareGapMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapMilestoneStore, cache: TTLCache<CareGapMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapMilestone? {
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

        func save(_ item: CareGapMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapMilestone] {
            return inner.list()
        }
    }

    static func newCachedCareGapMilestoneStore(_ inner: MemoryCareGapMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapMilestoneStore {
        return CachedCareGapMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap milestones. Empty fields match all.
    final class CareGapMilestoneQuery {
        var unit: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCopay: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapMilestone]) -> [CareGapMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapMilestones(_ store: any CareGapMilestoneStore, query: CareGapMilestoneQuery) -> [CareGapMilestone] {
        return query.apply(store.list())
    }
}
