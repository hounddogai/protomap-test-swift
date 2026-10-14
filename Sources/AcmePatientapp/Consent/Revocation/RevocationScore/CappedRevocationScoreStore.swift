import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped revocation scores by code.
    protocol CappedRevocationScoreStore {
        func find(_ code: String) -> CappedRevocationScore?
        func save(_ item: CappedRevocationScore)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRevocationScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRevocationScoreStore: CappedRevocationScoreStore {
        var items: [String: CappedRevocationScore]
        var order: [String]

        init(items: [String: CappedRevocationScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRevocationScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRevocationScore) {
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

        func list() -> [CappedRevocationScore] {
            var out: [CappedRevocationScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRevocationScoreStore() -> any CappedRevocationScoreStore {
        return MemoryCappedRevocationScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRevocationScoreStore: CappedRevocationScoreStore {
        var inner: MemoryCappedRevocationScoreStore
        var cache: TTLCache<CappedRevocationScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRevocationScoreStore, cache: TTLCache<CappedRevocationScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRevocationScore? {
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

        func save(_ item: CappedRevocationScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRevocationScore] {
            return inner.list()
        }
    }

    static func newCachedCappedRevocationScoreStore(_ inner: MemoryCappedRevocationScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRevocationScoreStore {
        return CachedCappedRevocationScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped revocation scores. Empty fields match all.
    final class CappedRevocationScoreQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRevocationScore) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRevocationScore]) -> [CappedRevocationScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRevocationScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRevocationScores(_ store: any CappedRevocationScoreStore, query: CappedRevocationScoreQuery) -> [CappedRevocationScore] {
        return query.apply(store.list())
    }
}
