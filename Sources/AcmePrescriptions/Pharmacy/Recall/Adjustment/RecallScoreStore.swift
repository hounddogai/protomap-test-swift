import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall scores by code.
    protocol RecallScoreStore {
        func find(_ code: String) -> RecallScore?
        func save(_ item: RecallScore)
        func remove(_ code: String) -> Bool
        func list() -> [RecallScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallScoreStore: RecallScoreStore {
        var items: [String: RecallScore]
        var order: [String]

        init(items: [String: RecallScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallScore) {
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

        func list() -> [RecallScore] {
            var out: [RecallScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallScoreStore() -> any RecallScoreStore {
        return MemoryRecallScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallScoreStore: RecallScoreStore {
        var inner: MemoryRecallScoreStore
        var cache: TTLCache<RecallScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallScoreStore, cache: TTLCache<RecallScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallScore? {
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

        func save(_ item: RecallScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallScore] {
            return inner.list()
        }
    }

    static func newCachedRecallScoreStore(_ inner: MemoryRecallScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallScoreStore {
        return CachedRecallScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall scores. Empty fields match all.
    final class RecallScoreQuery {
        var unit: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRatio: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallScore) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RecallScore]) -> [RecallScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallScores(_ store: any RecallScoreStore, query: RecallScoreQuery) -> [RecallScore] {
        return query.apply(store.list())
    }
}
