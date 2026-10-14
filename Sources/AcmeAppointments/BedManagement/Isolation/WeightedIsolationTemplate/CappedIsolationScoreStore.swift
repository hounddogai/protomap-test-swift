import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped isolation scores by code.
    protocol CappedIsolationScoreStore {
        func find(_ code: String) -> CappedIsolationScore?
        func save(_ item: CappedIsolationScore)
        func remove(_ code: String) -> Bool
        func list() -> [CappedIsolationScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedIsolationScoreStore: CappedIsolationScoreStore {
        var items: [String: CappedIsolationScore]
        var order: [String]

        init(items: [String: CappedIsolationScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedIsolationScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedIsolationScore) {
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

        func list() -> [CappedIsolationScore] {
            var out: [CappedIsolationScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedIsolationScoreStore() -> any CappedIsolationScoreStore {
        return MemoryCappedIsolationScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedIsolationScoreStore: CappedIsolationScoreStore {
        var inner: MemoryCappedIsolationScoreStore
        var cache: TTLCache<CappedIsolationScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedIsolationScoreStore, cache: TTLCache<CappedIsolationScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedIsolationScore? {
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

        func save(_ item: CappedIsolationScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedIsolationScore] {
            return inner.list()
        }
    }

    static func newCachedCappedIsolationScoreStore(_ inner: MemoryCappedIsolationScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedIsolationScoreStore {
        return CachedCappedIsolationScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped isolation scores. Empty fields match all.
    final class CappedIsolationScoreQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedIsolationScore) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedIsolationScore]) -> [CappedIsolationScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedIsolationScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedIsolationScores(_ store: any CappedIsolationScoreStore, query: CappedIsolationScoreQuery) -> [CappedIsolationScore] {
        return query.apply(store.list())
    }
}
