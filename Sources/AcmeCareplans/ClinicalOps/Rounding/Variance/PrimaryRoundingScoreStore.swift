import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary rounding scores by code.
    protocol PrimaryRoundingScoreStore {
        func find(_ code: String) -> PrimaryRoundingScore?
        func save(_ item: PrimaryRoundingScore)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRoundingScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRoundingScoreStore: PrimaryRoundingScoreStore {
        var items: [String: PrimaryRoundingScore]
        var order: [String]

        init(items: [String: PrimaryRoundingScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRoundingScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRoundingScore) {
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

        func list() -> [PrimaryRoundingScore] {
            var out: [PrimaryRoundingScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRoundingScoreStore() -> any PrimaryRoundingScoreStore {
        return MemoryPrimaryRoundingScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRoundingScoreStore: PrimaryRoundingScoreStore {
        var inner: MemoryPrimaryRoundingScoreStore
        var cache: TTLCache<PrimaryRoundingScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRoundingScoreStore, cache: TTLCache<PrimaryRoundingScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRoundingScore? {
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

        func save(_ item: PrimaryRoundingScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRoundingScore] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRoundingScoreStore(_ inner: MemoryPrimaryRoundingScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRoundingScoreStore {
        return CachedPrimaryRoundingScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary rounding scores. Empty fields match all.
    final class PrimaryRoundingScoreQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRoundingScore) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryRoundingScore]) -> [PrimaryRoundingScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRoundingScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRoundingScores(_ store: any PrimaryRoundingScoreStore, query: PrimaryRoundingScoreQuery) -> [PrimaryRoundingScore] {
        return query.apply(store.list())
    }
}
