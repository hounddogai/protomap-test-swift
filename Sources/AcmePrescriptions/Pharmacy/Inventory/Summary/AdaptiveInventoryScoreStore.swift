import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive inventory scores by code.
    protocol AdaptiveInventoryScoreStore {
        func find(_ code: String) -> AdaptiveInventoryScore?
        func save(_ item: AdaptiveInventoryScore)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveInventoryScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveInventoryScoreStore: AdaptiveInventoryScoreStore {
        var items: [String: AdaptiveInventoryScore]
        var order: [String]

        init(items: [String: AdaptiveInventoryScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveInventoryScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveInventoryScore) {
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

        func list() -> [AdaptiveInventoryScore] {
            var out: [AdaptiveInventoryScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveInventoryScoreStore() -> any AdaptiveInventoryScoreStore {
        return MemoryAdaptiveInventoryScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveInventoryScoreStore: AdaptiveInventoryScoreStore {
        var inner: MemoryAdaptiveInventoryScoreStore
        var cache: TTLCache<AdaptiveInventoryScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveInventoryScoreStore, cache: TTLCache<AdaptiveInventoryScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveInventoryScore? {
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

        func save(_ item: AdaptiveInventoryScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveInventoryScore] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveInventoryScoreStore(_ inner: MemoryAdaptiveInventoryScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveInventoryScoreStore {
        return CachedAdaptiveInventoryScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive inventory scores. Empty fields match all.
    final class AdaptiveInventoryScoreQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveInventoryScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveInventoryScore]) -> [AdaptiveInventoryScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveInventoryScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveInventoryScores(_ store: any AdaptiveInventoryScoreStore, query: AdaptiveInventoryScoreQuery) -> [AdaptiveInventoryScore] {
        return query.apply(store.list())
    }
}
