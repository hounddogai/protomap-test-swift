import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial scores by code.
    protocol DenialScoreStore {
        func find(_ code: String) -> DenialScore?
        func save(_ item: DenialScore)
        func remove(_ code: String) -> Bool
        func list() -> [DenialScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialScoreStore: DenialScoreStore {
        var items: [String: DenialScore]
        var order: [String]

        init(items: [String: DenialScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialScore) {
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

        func list() -> [DenialScore] {
            var out: [DenialScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialScoreStore() -> any DenialScoreStore {
        return MemoryDenialScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialScoreStore: DenialScoreStore {
        var inner: MemoryDenialScoreStore
        var cache: TTLCache<DenialScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialScoreStore, cache: TTLCache<DenialScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialScore? {
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

        func save(_ item: DenialScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialScore] {
            return inner.list()
        }
    }

    static func newCachedDenialScoreStore(_ inner: MemoryDenialScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialScoreStore {
        return CachedDenialScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial scores. Empty fields match all.
    final class DenialScoreQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialScore]) -> [DenialScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialScores(_ store: any DenialScoreStore, query: DenialScoreQuery) -> [DenialScore] {
        return query.apply(store.list())
    }
}
