import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read scores by code.
    protocol ReadScoreStore {
        func find(_ code: String) -> ReadScore?
        func save(_ item: ReadScore)
        func remove(_ code: String) -> Bool
        func list() -> [ReadScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadScoreStore: ReadScoreStore {
        var items: [String: ReadScore]
        var order: [String]

        init(items: [String: ReadScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadScore) {
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

        func list() -> [ReadScore] {
            var out: [ReadScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadScoreStore() -> any ReadScoreStore {
        return MemoryReadScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadScoreStore: ReadScoreStore {
        var inner: MemoryReadScoreStore
        var cache: TTLCache<ReadScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadScoreStore, cache: TTLCache<ReadScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadScore? {
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

        func save(_ item: ReadScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadScore] {
            return inner.list()
        }
    }

    static func newCachedReadScoreStore(_ inner: MemoryReadScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadScoreStore {
        return CachedReadScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read scores. Empty fields match all.
    final class ReadScoreQuery {
        var category: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadScore) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadScore]) -> [ReadScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadScores(_ store: any ReadScoreStore, query: ReadScoreQuery) -> [ReadScore] {
        return query.apply(store.list())
    }
}
