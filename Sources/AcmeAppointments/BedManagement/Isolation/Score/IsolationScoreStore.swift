import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation scores by code.
    protocol IsolationScoreStore {
        func find(_ code: String) -> IsolationScore?
        func save(_ item: IsolationScore)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationScoreStore: IsolationScoreStore {
        var items: [String: IsolationScore]
        var order: [String]

        init(items: [String: IsolationScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationScore) {
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

        func list() -> [IsolationScore] {
            var out: [IsolationScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationScoreStore() -> any IsolationScoreStore {
        return MemoryIsolationScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationScoreStore: IsolationScoreStore {
        var inner: MemoryIsolationScoreStore
        var cache: TTLCache<IsolationScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationScoreStore, cache: TTLCache<IsolationScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationScore? {
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

        func save(_ item: IsolationScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationScore] {
            return inner.list()
        }
    }

    static func newCachedIsolationScoreStore(_ inner: MemoryIsolationScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationScoreStore {
        return CachedIsolationScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation scores. Empty fields match all.
    final class IsolationScoreQuery {
        var country: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRefills: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationScore) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [IsolationScore]) -> [IsolationScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationScores(_ store: any IsolationScoreStore, query: IsolationScoreQuery) -> [IsolationScore] {
        return query.apply(store.list())
    }
}
