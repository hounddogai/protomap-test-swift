import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict formulary scores by code.
    protocol StrictFormularyScoreStore {
        func find(_ code: String) -> StrictFormularyScore?
        func save(_ item: StrictFormularyScore)
        func remove(_ code: String) -> Bool
        func list() -> [StrictFormularyScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictFormularyScoreStore: StrictFormularyScoreStore {
        var items: [String: StrictFormularyScore]
        var order: [String]

        init(items: [String: StrictFormularyScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictFormularyScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictFormularyScore) {
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

        func list() -> [StrictFormularyScore] {
            var out: [StrictFormularyScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictFormularyScoreStore() -> any StrictFormularyScoreStore {
        return MemoryStrictFormularyScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictFormularyScoreStore: StrictFormularyScoreStore {
        var inner: MemoryStrictFormularyScoreStore
        var cache: TTLCache<StrictFormularyScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictFormularyScoreStore, cache: TTLCache<StrictFormularyScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictFormularyScore? {
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

        func save(_ item: StrictFormularyScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictFormularyScore] {
            return inner.list()
        }
    }

    static func newCachedStrictFormularyScoreStore(_ inner: MemoryStrictFormularyScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictFormularyScoreStore {
        return CachedStrictFormularyScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict formulary scores. Empty fields match all.
    final class StrictFormularyScoreQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictFormularyScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictFormularyScore]) -> [StrictFormularyScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictFormularyScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictFormularyScores(_ store: any StrictFormularyScoreStore, query: StrictFormularyScoreQuery) -> [StrictFormularyScore] {
        return query.apply(store.list())
    }
}
