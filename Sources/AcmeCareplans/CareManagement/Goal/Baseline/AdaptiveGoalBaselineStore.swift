import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive goal baselines by code.
    protocol AdaptiveGoalBaselineStore {
        func find(_ code: String) -> AdaptiveGoalBaseline?
        func save(_ item: AdaptiveGoalBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveGoalBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveGoalBaselineStore: AdaptiveGoalBaselineStore {
        var items: [String: AdaptiveGoalBaseline]
        var order: [String]

        init(items: [String: AdaptiveGoalBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveGoalBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveGoalBaseline) {
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

        func list() -> [AdaptiveGoalBaseline] {
            var out: [AdaptiveGoalBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveGoalBaselineStore() -> any AdaptiveGoalBaselineStore {
        return MemoryAdaptiveGoalBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveGoalBaselineStore: AdaptiveGoalBaselineStore {
        var inner: MemoryAdaptiveGoalBaselineStore
        var cache: TTLCache<AdaptiveGoalBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveGoalBaselineStore, cache: TTLCache<AdaptiveGoalBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveGoalBaseline? {
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

        func save(_ item: AdaptiveGoalBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveGoalBaseline] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveGoalBaselineStore(_ inner: MemoryAdaptiveGoalBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveGoalBaselineStore {
        return CachedAdaptiveGoalBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive goal baselines. Empty fields match all.
    final class AdaptiveGoalBaselineQuery {
        var category: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveGoalBaseline) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveGoalBaseline]) -> [AdaptiveGoalBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveGoalBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveGoalBaselines(_ store: any AdaptiveGoalBaselineStore, query: AdaptiveGoalBaselineQuery) -> [AdaptiveGoalBaseline] {
        return query.apply(store.list())
    }
}
