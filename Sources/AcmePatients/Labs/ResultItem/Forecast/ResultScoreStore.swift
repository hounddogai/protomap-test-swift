import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result scores by code.
    protocol ResultScoreStore {
        func find(_ code: String) -> ResultScore?
        func save(_ item: ResultScore)
        func remove(_ code: String) -> Bool
        func list() -> [ResultScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultScoreStore: ResultScoreStore {
        var items: [String: ResultScore]
        var order: [String]

        init(items: [String: ResultScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultScore) {
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

        func list() -> [ResultScore] {
            var out: [ResultScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultScoreStore() -> any ResultScoreStore {
        return MemoryResultScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultScoreStore: ResultScoreStore {
        var inner: MemoryResultScoreStore
        var cache: TTLCache<ResultScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultScoreStore, cache: TTLCache<ResultScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultScore? {
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

        func save(_ item: ResultScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultScore] {
            return inner.list()
        }
    }

    static func newCachedResultScoreStore(_ inner: MemoryResultScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultScoreStore {
        return CachedResultScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result scores. Empty fields match all.
    final class ResultScoreQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultScore) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultScore]) -> [ResultScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultScores(_ store: any ResultScoreStore, query: ResultScoreQuery) -> [ResultScore] {
        return query.apply(store.list())
    }
}
