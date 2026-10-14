import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession scores by code.
    protocol AccessionScoreStore {
        func find(_ code: String) -> AccessionScore?
        func save(_ item: AccessionScore)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionScoreStore: AccessionScoreStore {
        var items: [String: AccessionScore]
        var order: [String]

        init(items: [String: AccessionScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionScore) {
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

        func list() -> [AccessionScore] {
            var out: [AccessionScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionScoreStore() -> any AccessionScoreStore {
        return MemoryAccessionScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionScoreStore: AccessionScoreStore {
        var inner: MemoryAccessionScoreStore
        var cache: TTLCache<AccessionScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionScoreStore, cache: TTLCache<AccessionScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionScore? {
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

        func save(_ item: AccessionScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionScore] {
            return inner.list()
        }
    }

    static func newCachedAccessionScoreStore(_ inner: MemoryAccessionScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionScoreStore {
        return CachedAccessionScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession scores. Empty fields match all.
    final class AccessionScoreQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionScore) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [AccessionScore]) -> [AccessionScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionScores(_ store: any AccessionScoreStore, query: AccessionScoreQuery) -> [AccessionScore] {
        return query.apply(store.list())
    }
}
