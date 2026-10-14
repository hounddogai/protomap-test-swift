import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal bundles by code.
    protocol GoalBundleStore {
        func find(_ code: String) -> GoalBundle?
        func save(_ item: GoalBundle)
        func remove(_ code: String) -> Bool
        func list() -> [GoalBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalBundleStore: GoalBundleStore {
        var items: [String: GoalBundle]
        var order: [String]

        init(items: [String: GoalBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalBundle) {
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

        func list() -> [GoalBundle] {
            var out: [GoalBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalBundleStore() -> any GoalBundleStore {
        return MemoryGoalBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalBundleStore: GoalBundleStore {
        var inner: MemoryGoalBundleStore
        var cache: TTLCache<GoalBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalBundleStore, cache: TTLCache<GoalBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalBundle? {
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

        func save(_ item: GoalBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalBundle] {
            return inner.list()
        }
    }

    static func newCachedGoalBundleStore(_ inner: MemoryGoalBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalBundleStore {
        return CachedGoalBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal bundles. Empty fields match all.
    final class GoalBundleQuery {
        var region: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMargin: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalBundle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [GoalBundle]) -> [GoalBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalBundles(_ store: any GoalBundleStore, query: GoalBundleQuery) -> [GoalBundle] {
        return query.apply(store.list())
    }
}
