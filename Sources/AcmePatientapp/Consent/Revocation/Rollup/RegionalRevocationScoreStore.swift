import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional revocation scores by code.
    protocol RegionalRevocationScoreStore {
        func find(_ code: String) -> RegionalRevocationScore?
        func save(_ item: RegionalRevocationScore)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRevocationScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRevocationScoreStore: RegionalRevocationScoreStore {
        var items: [String: RegionalRevocationScore]
        var order: [String]

        init(items: [String: RegionalRevocationScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRevocationScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRevocationScore) {
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

        func list() -> [RegionalRevocationScore] {
            var out: [RegionalRevocationScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRevocationScoreStore() -> any RegionalRevocationScoreStore {
        return MemoryRegionalRevocationScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRevocationScoreStore: RegionalRevocationScoreStore {
        var inner: MemoryRegionalRevocationScoreStore
        var cache: TTLCache<RegionalRevocationScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRevocationScoreStore, cache: TTLCache<RegionalRevocationScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRevocationScore? {
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

        func save(_ item: RegionalRevocationScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRevocationScore] {
            return inner.list()
        }
    }

    static func newCachedRegionalRevocationScoreStore(_ inner: MemoryRegionalRevocationScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRevocationScoreStore {
        return CachedRegionalRevocationScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional revocation scores. Empty fields match all.
    final class RegionalRevocationScoreQuery {
        var country: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minSequence: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRevocationScore) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalRevocationScore]) -> [RegionalRevocationScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRevocationScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRevocationScores(_ store: any RegionalRevocationScoreStore, query: RegionalRevocationScoreQuery) -> [RegionalRevocationScore] {
        return query.apply(store.list())
    }
}
