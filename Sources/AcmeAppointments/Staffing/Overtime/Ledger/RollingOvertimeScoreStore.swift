import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling overtime scores by code.
    protocol RollingOvertimeScoreStore {
        func find(_ code: String) -> RollingOvertimeScore?
        func save(_ item: RollingOvertimeScore)
        func remove(_ code: String) -> Bool
        func list() -> [RollingOvertimeScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingOvertimeScoreStore: RollingOvertimeScoreStore {
        var items: [String: RollingOvertimeScore]
        var order: [String]

        init(items: [String: RollingOvertimeScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingOvertimeScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingOvertimeScore) {
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

        func list() -> [RollingOvertimeScore] {
            var out: [RollingOvertimeScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingOvertimeScoreStore() -> any RollingOvertimeScoreStore {
        return MemoryRollingOvertimeScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingOvertimeScoreStore: RollingOvertimeScoreStore {
        var inner: MemoryRollingOvertimeScoreStore
        var cache: TTLCache<RollingOvertimeScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingOvertimeScoreStore, cache: TTLCache<RollingOvertimeScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingOvertimeScore? {
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

        func save(_ item: RollingOvertimeScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingOvertimeScore] {
            return inner.list()
        }
    }

    static func newCachedRollingOvertimeScoreStore(_ inner: MemoryRollingOvertimeScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingOvertimeScoreStore {
        return CachedRollingOvertimeScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling overtime scores. Empty fields match all.
    final class RollingOvertimeScoreQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingOvertimeScore) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingOvertimeScore]) -> [RollingOvertimeScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingOvertimeScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingOvertimeScores(_ store: any RollingOvertimeScoreStore, query: RollingOvertimeScoreQuery) -> [RollingOvertimeScore] {
        return query.apply(store.list())
    }
}
