import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary study scores by code.
    protocol PrimaryStudyScoreStore {
        func find(_ code: String) -> PrimaryStudyScore?
        func save(_ item: PrimaryStudyScore)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryStudyScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryStudyScoreStore: PrimaryStudyScoreStore {
        var items: [String: PrimaryStudyScore]
        var order: [String]

        init(items: [String: PrimaryStudyScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryStudyScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryStudyScore) {
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

        func list() -> [PrimaryStudyScore] {
            var out: [PrimaryStudyScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryStudyScoreStore() -> any PrimaryStudyScoreStore {
        return MemoryPrimaryStudyScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryStudyScoreStore: PrimaryStudyScoreStore {
        var inner: MemoryPrimaryStudyScoreStore
        var cache: TTLCache<PrimaryStudyScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryStudyScoreStore, cache: TTLCache<PrimaryStudyScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryStudyScore? {
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

        func save(_ item: PrimaryStudyScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryStudyScore] {
            return inner.list()
        }
    }

    static func newCachedPrimaryStudyScoreStore(_ inner: MemoryPrimaryStudyScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryStudyScoreStore {
        return CachedPrimaryStudyScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary study scores. Empty fields match all.
    final class PrimaryStudyScoreQuery {
        var ward: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryStudyScore) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryStudyScore]) -> [PrimaryStudyScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryStudyScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryStudyScores(_ store: any PrimaryStudyScoreStore, query: PrimaryStudyScoreQuery) -> [PrimaryStudyScore] {
        return query.apply(store.list())
    }
}
