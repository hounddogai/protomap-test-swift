import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict shift scores by code.
    protocol StrictShiftScoreStore {
        func find(_ code: String) -> StrictShiftScore?
        func save(_ item: StrictShiftScore)
        func remove(_ code: String) -> Bool
        func list() -> [StrictShiftScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictShiftScoreStore: StrictShiftScoreStore {
        var items: [String: StrictShiftScore]
        var order: [String]

        init(items: [String: StrictShiftScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictShiftScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictShiftScore) {
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

        func list() -> [StrictShiftScore] {
            var out: [StrictShiftScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictShiftScoreStore() -> any StrictShiftScoreStore {
        return MemoryStrictShiftScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictShiftScoreStore: StrictShiftScoreStore {
        var inner: MemoryStrictShiftScoreStore
        var cache: TTLCache<StrictShiftScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictShiftScoreStore, cache: TTLCache<StrictShiftScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictShiftScore? {
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

        func save(_ item: StrictShiftScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictShiftScore] {
            return inner.list()
        }
    }

    static func newCachedStrictShiftScoreStore(_ inner: MemoryStrictShiftScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictShiftScoreStore {
        return CachedStrictShiftScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict shift scores. Empty fields match all.
    final class StrictShiftScoreQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictShiftScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictShiftScore]) -> [StrictShiftScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictShiftScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictShiftScores(_ store: any StrictShiftScoreStore, query: StrictShiftScoreQuery) -> [StrictShiftScore] {
        return query.apply(store.list())
    }
}
