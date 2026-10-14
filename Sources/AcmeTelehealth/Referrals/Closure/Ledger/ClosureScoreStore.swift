import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure scores by code.
    protocol ClosureScoreStore {
        func find(_ code: String) -> ClosureScore?
        func save(_ item: ClosureScore)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureScoreStore: ClosureScoreStore {
        var items: [String: ClosureScore]
        var order: [String]

        init(items: [String: ClosureScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureScore) {
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

        func list() -> [ClosureScore] {
            var out: [ClosureScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureScoreStore() -> any ClosureScoreStore {
        return MemoryClosureScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureScoreStore: ClosureScoreStore {
        var inner: MemoryClosureScoreStore
        var cache: TTLCache<ClosureScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureScoreStore, cache: TTLCache<ClosureScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureScore? {
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

        func save(_ item: ClosureScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureScore] {
            return inner.list()
        }
    }

    static func newCachedClosureScoreStore(_ inner: MemoryClosureScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureScoreStore {
        return CachedClosureScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure scores. Empty fields match all.
    final class ClosureScoreQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureScore]) -> [ClosureScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureScores(_ store: any ClosureScoreStore, query: ClosureScoreQuery) -> [ClosureScore] {
        return query.apply(store.list())
    }
}
