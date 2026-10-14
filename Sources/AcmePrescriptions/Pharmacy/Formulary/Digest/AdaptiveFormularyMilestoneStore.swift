import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive formulary milestones by code.
    protocol AdaptiveFormularyMilestoneStore {
        func find(_ code: String) -> AdaptiveFormularyMilestone?
        func save(_ item: AdaptiveFormularyMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveFormularyMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveFormularyMilestoneStore: AdaptiveFormularyMilestoneStore {
        var items: [String: AdaptiveFormularyMilestone]
        var order: [String]

        init(items: [String: AdaptiveFormularyMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveFormularyMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveFormularyMilestone) {
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

        func list() -> [AdaptiveFormularyMilestone] {
            var out: [AdaptiveFormularyMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveFormularyMilestoneStore() -> any AdaptiveFormularyMilestoneStore {
        return MemoryAdaptiveFormularyMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveFormularyMilestoneStore: AdaptiveFormularyMilestoneStore {
        var inner: MemoryAdaptiveFormularyMilestoneStore
        var cache: TTLCache<AdaptiveFormularyMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveFormularyMilestoneStore, cache: TTLCache<AdaptiveFormularyMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveFormularyMilestone? {
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

        func save(_ item: AdaptiveFormularyMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveFormularyMilestone] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveFormularyMilestoneStore(_ inner: MemoryAdaptiveFormularyMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveFormularyMilestoneStore {
        return CachedAdaptiveFormularyMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive formulary milestones. Empty fields match all.
    final class AdaptiveFormularyMilestoneQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveFormularyMilestone) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveFormularyMilestone]) -> [AdaptiveFormularyMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveFormularyMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveFormularyMilestones(_ store: any AdaptiveFormularyMilestoneStore, query: AdaptiveFormularyMilestoneQuery) -> [AdaptiveFormularyMilestone] {
        return query.apply(store.list())
    }
}
