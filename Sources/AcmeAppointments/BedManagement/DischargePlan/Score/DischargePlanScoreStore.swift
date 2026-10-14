import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan scores by code.
    protocol DischargePlanScoreStore {
        func find(_ code: String) -> DischargePlanScore?
        func save(_ item: DischargePlanScore)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanScoreStore: DischargePlanScoreStore {
        var items: [String: DischargePlanScore]
        var order: [String]

        init(items: [String: DischargePlanScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanScore) {
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

        func list() -> [DischargePlanScore] {
            var out: [DischargePlanScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanScoreStore() -> any DischargePlanScoreStore {
        return MemoryDischargePlanScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanScoreStore: DischargePlanScoreStore {
        var inner: MemoryDischargePlanScoreStore
        var cache: TTLCache<DischargePlanScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanScoreStore, cache: TTLCache<DischargePlanScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanScore? {
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

        func save(_ item: DischargePlanScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanScore] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanScoreStore(_ inner: MemoryDischargePlanScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanScoreStore {
        return CachedDischargePlanScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan scores. Empty fields match all.
    final class DischargePlanScoreQuery {
        var segment: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRefills: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanScore) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [DischargePlanScore]) -> [DischargePlanScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanScores(_ store: any DischargePlanScoreStore, query: DischargePlanScoreQuery) -> [DischargePlanScore] {
        return query.apply(store.list())
    }
}
