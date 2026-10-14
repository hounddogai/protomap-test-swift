import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist scores by code.
    protocol WorklistScoreStore {
        func find(_ code: String) -> WorklistScore?
        func save(_ item: WorklistScore)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistScoreStore: WorklistScoreStore {
        var items: [String: WorklistScore]
        var order: [String]

        init(items: [String: WorklistScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistScore) {
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

        func list() -> [WorklistScore] {
            var out: [WorklistScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistScoreStore() -> any WorklistScoreStore {
        return MemoryWorklistScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistScoreStore: WorklistScoreStore {
        var inner: MemoryWorklistScoreStore
        var cache: TTLCache<WorklistScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistScoreStore, cache: TTLCache<WorklistScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistScore? {
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

        func save(_ item: WorklistScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistScore] {
            return inner.list()
        }
    }

    static func newCachedWorklistScoreStore(_ inner: MemoryWorklistScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistScoreStore {
        return CachedWorklistScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist scores. Empty fields match all.
    final class WorklistScoreQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistScore) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [WorklistScore]) -> [WorklistScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistScores(_ store: any WorklistScoreStore, query: WorklistScoreQuery) -> [WorklistScore] {
        return query.apply(store.list())
    }
}
