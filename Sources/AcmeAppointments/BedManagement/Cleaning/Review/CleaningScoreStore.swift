import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning scores by code.
    protocol CleaningScoreStore {
        func find(_ code: String) -> CleaningScore?
        func save(_ item: CleaningScore)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningScoreStore: CleaningScoreStore {
        var items: [String: CleaningScore]
        var order: [String]

        init(items: [String: CleaningScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningScore) {
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

        func list() -> [CleaningScore] {
            var out: [CleaningScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningScoreStore() -> any CleaningScoreStore {
        return MemoryCleaningScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningScoreStore: CleaningScoreStore {
        var inner: MemoryCleaningScoreStore
        var cache: TTLCache<CleaningScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningScoreStore, cache: TTLCache<CleaningScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningScore? {
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

        func save(_ item: CleaningScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningScore] {
            return inner.list()
        }
    }

    static func newCachedCleaningScoreStore(_ inner: MemoryCleaningScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningScoreStore {
        return CachedCleaningScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning scores. Empty fields match all.
    final class CleaningScoreQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningScore]) -> [CleaningScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningScores(_ store: any CleaningScoreStore, query: CleaningScoreQuery) -> [CleaningScore] {
        return query.apply(store.list())
    }
}
