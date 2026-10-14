import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary denial scores by code.
    protocol PrimaryDenialScoreStore {
        func find(_ code: String) -> PrimaryDenialScore?
        func save(_ item: PrimaryDenialScore)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryDenialScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryDenialScoreStore: PrimaryDenialScoreStore {
        var items: [String: PrimaryDenialScore]
        var order: [String]

        init(items: [String: PrimaryDenialScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryDenialScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryDenialScore) {
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

        func list() -> [PrimaryDenialScore] {
            var out: [PrimaryDenialScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryDenialScoreStore() -> any PrimaryDenialScoreStore {
        return MemoryPrimaryDenialScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryDenialScoreStore: PrimaryDenialScoreStore {
        var inner: MemoryPrimaryDenialScoreStore
        var cache: TTLCache<PrimaryDenialScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryDenialScoreStore, cache: TTLCache<PrimaryDenialScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryDenialScore? {
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

        func save(_ item: PrimaryDenialScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryDenialScore] {
            return inner.list()
        }
    }

    static func newCachedPrimaryDenialScoreStore(_ inner: MemoryPrimaryDenialScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryDenialScoreStore {
        return CachedPrimaryDenialScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary denial scores. Empty fields match all.
    final class PrimaryDenialScoreQuery {
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

        func matches(_ item: PrimaryDenialScore) -> Bool {
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

        func apply(_ items: [PrimaryDenialScore]) -> [PrimaryDenialScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryDenialScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryDenialScores(_ store: any PrimaryDenialScoreStore, query: PrimaryDenialScoreQuery) -> [PrimaryDenialScore] {
        return query.apply(store.list())
    }
}
