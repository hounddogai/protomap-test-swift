import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling float pool scores by code.
    protocol RollingFloatPoolScoreStore {
        func find(_ code: String) -> RollingFloatPoolScore?
        func save(_ item: RollingFloatPoolScore)
        func remove(_ code: String) -> Bool
        func list() -> [RollingFloatPoolScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingFloatPoolScoreStore: RollingFloatPoolScoreStore {
        var items: [String: RollingFloatPoolScore]
        var order: [String]

        init(items: [String: RollingFloatPoolScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingFloatPoolScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingFloatPoolScore) {
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

        func list() -> [RollingFloatPoolScore] {
            var out: [RollingFloatPoolScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingFloatPoolScoreStore() -> any RollingFloatPoolScoreStore {
        return MemoryRollingFloatPoolScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingFloatPoolScoreStore: RollingFloatPoolScoreStore {
        var inner: MemoryRollingFloatPoolScoreStore
        var cache: TTLCache<RollingFloatPoolScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingFloatPoolScoreStore, cache: TTLCache<RollingFloatPoolScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingFloatPoolScore? {
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

        func save(_ item: RollingFloatPoolScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingFloatPoolScore] {
            return inner.list()
        }
    }

    static func newCachedRollingFloatPoolScoreStore(_ inner: MemoryRollingFloatPoolScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingFloatPoolScoreStore {
        return CachedRollingFloatPoolScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling float pool scores. Empty fields match all.
    final class RollingFloatPoolScoreQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingFloatPoolScore) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [RollingFloatPoolScore]) -> [RollingFloatPoolScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingFloatPoolScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingFloatPoolScores(_ store: any RollingFloatPoolScoreStore, query: RollingFloatPoolScoreQuery) -> [RollingFloatPoolScore] {
        return query.apply(store.list())
    }
}
