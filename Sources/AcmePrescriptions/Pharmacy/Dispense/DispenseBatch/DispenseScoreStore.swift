import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense scores by code.
    protocol DispenseScoreStore {
        func find(_ code: String) -> DispenseScore?
        func save(_ item: DispenseScore)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseScoreStore: DispenseScoreStore {
        var items: [String: DispenseScore]
        var order: [String]

        init(items: [String: DispenseScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseScore) {
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

        func list() -> [DispenseScore] {
            var out: [DispenseScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseScoreStore() -> any DispenseScoreStore {
        return MemoryDispenseScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseScoreStore: DispenseScoreStore {
        var inner: MemoryDispenseScoreStore
        var cache: TTLCache<DispenseScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseScoreStore, cache: TTLCache<DispenseScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseScore? {
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

        func save(_ item: DispenseScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseScore] {
            return inner.list()
        }
    }

    static func newCachedDispenseScoreStore(_ inner: MemoryDispenseScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseScoreStore {
        return CachedDispenseScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense scores. Empty fields match all.
    final class DispenseScoreQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseScore) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseScore]) -> [DispenseScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseScores(_ store: any DispenseScoreStore, query: DispenseScoreQuery) -> [DispenseScore] {
        return query.apply(store.list())
    }
}
