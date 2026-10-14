import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy goal cycles by code.
    protocol LegacyGoalCycleStore {
        func find(_ code: String) -> LegacyGoalCycle?
        func save(_ item: LegacyGoalCycle)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyGoalCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyGoalCycleStore: LegacyGoalCycleStore {
        var items: [String: LegacyGoalCycle]
        var order: [String]

        init(items: [String: LegacyGoalCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyGoalCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyGoalCycle) {
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

        func list() -> [LegacyGoalCycle] {
            var out: [LegacyGoalCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyGoalCycleStore() -> any LegacyGoalCycleStore {
        return MemoryLegacyGoalCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyGoalCycleStore: LegacyGoalCycleStore {
        var inner: MemoryLegacyGoalCycleStore
        var cache: TTLCache<LegacyGoalCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyGoalCycleStore, cache: TTLCache<LegacyGoalCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyGoalCycle? {
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

        func save(_ item: LegacyGoalCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyGoalCycle] {
            return inner.list()
        }
    }

    static func newCachedLegacyGoalCycleStore(_ inner: MemoryLegacyGoalCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyGoalCycleStore {
        return CachedLegacyGoalCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy goal cycles. Empty fields match all.
    final class LegacyGoalCycleQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyGoalCycle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyGoalCycle]) -> [LegacyGoalCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyGoalCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyGoalCycles(_ store: any LegacyGoalCycleStore, query: LegacyGoalCycleQuery) -> [LegacyGoalCycle] {
        return query.apply(store.list())
    }
}
