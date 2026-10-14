import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict transfer scores by code.
    protocol StrictTransferScoreStore {
        func find(_ code: String) -> StrictTransferScore?
        func save(_ item: StrictTransferScore)
        func remove(_ code: String) -> Bool
        func list() -> [StrictTransferScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictTransferScoreStore: StrictTransferScoreStore {
        var items: [String: StrictTransferScore]
        var order: [String]

        init(items: [String: StrictTransferScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictTransferScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictTransferScore) {
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

        func list() -> [StrictTransferScore] {
            var out: [StrictTransferScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictTransferScoreStore() -> any StrictTransferScoreStore {
        return MemoryStrictTransferScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictTransferScoreStore: StrictTransferScoreStore {
        var inner: MemoryStrictTransferScoreStore
        var cache: TTLCache<StrictTransferScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictTransferScoreStore, cache: TTLCache<StrictTransferScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictTransferScore? {
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

        func save(_ item: StrictTransferScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictTransferScore] {
            return inner.list()
        }
    }

    static func newCachedStrictTransferScoreStore(_ inner: MemoryStrictTransferScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictTransferScoreStore {
        return CachedStrictTransferScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict transfer scores. Empty fields match all.
    final class StrictTransferScoreQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictTransferScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictTransferScore]) -> [StrictTransferScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictTransferScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictTransferScores(_ store: any StrictTransferScoreStore, query: StrictTransferScoreQuery) -> [StrictTransferScore] {
        return query.apply(store.list())
    }
}
