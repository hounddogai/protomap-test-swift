import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling accession scores by code.
    protocol RollingAccessionScoreStore {
        func find(_ code: String) -> RollingAccessionScore?
        func save(_ item: RollingAccessionScore)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAccessionScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAccessionScoreStore: RollingAccessionScoreStore {
        var items: [String: RollingAccessionScore]
        var order: [String]

        init(items: [String: RollingAccessionScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAccessionScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAccessionScore) {
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

        func list() -> [RollingAccessionScore] {
            var out: [RollingAccessionScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAccessionScoreStore() -> any RollingAccessionScoreStore {
        return MemoryRollingAccessionScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAccessionScoreStore: RollingAccessionScoreStore {
        var inner: MemoryRollingAccessionScoreStore
        var cache: TTLCache<RollingAccessionScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAccessionScoreStore, cache: TTLCache<RollingAccessionScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAccessionScore? {
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

        func save(_ item: RollingAccessionScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAccessionScore] {
            return inner.list()
        }
    }

    static func newCachedRollingAccessionScoreStore(_ inner: MemoryRollingAccessionScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAccessionScoreStore {
        return CachedRollingAccessionScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling accession scores. Empty fields match all.
    final class RollingAccessionScoreQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAccessionScore) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingAccessionScore]) -> [RollingAccessionScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAccessionScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAccessionScores(_ store: any RollingAccessionScoreStore, query: RollingAccessionScoreQuery) -> [RollingAccessionScore] {
        return query.apply(store.list())
    }
}
