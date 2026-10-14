import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling discharge plan scores by code.
    protocol RollingDischargePlanScoreStore {
        func find(_ code: String) -> RollingDischargePlanScore?
        func save(_ item: RollingDischargePlanScore)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDischargePlanScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDischargePlanScoreStore: RollingDischargePlanScoreStore {
        var items: [String: RollingDischargePlanScore]
        var order: [String]

        init(items: [String: RollingDischargePlanScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDischargePlanScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDischargePlanScore) {
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

        func list() -> [RollingDischargePlanScore] {
            var out: [RollingDischargePlanScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDischargePlanScoreStore() -> any RollingDischargePlanScoreStore {
        return MemoryRollingDischargePlanScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDischargePlanScoreStore: RollingDischargePlanScoreStore {
        var inner: MemoryRollingDischargePlanScoreStore
        var cache: TTLCache<RollingDischargePlanScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDischargePlanScoreStore, cache: TTLCache<RollingDischargePlanScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDischargePlanScore? {
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

        func save(_ item: RollingDischargePlanScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDischargePlanScore] {
            return inner.list()
        }
    }

    static func newCachedRollingDischargePlanScoreStore(_ inner: MemoryRollingDischargePlanScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDischargePlanScoreStore {
        return CachedRollingDischargePlanScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling discharge plan scores. Empty fields match all.
    final class RollingDischargePlanScoreQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingDischargePlanScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingDischargePlanScore]) -> [RollingDischargePlanScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDischargePlanScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDischargePlanScores(_ store: any RollingDischargePlanScoreStore, query: RollingDischargePlanScoreQuery) -> [RollingDischargePlanScore] {
        return query.apply(store.list())
    }
}
