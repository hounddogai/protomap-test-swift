import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge scores by code.
    protocol ChargeScoreStore {
        func find(_ code: String) -> ChargeScore?
        func save(_ item: ChargeScore)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeScoreStore: ChargeScoreStore {
        var items: [String: ChargeScore]
        var order: [String]

        init(items: [String: ChargeScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeScore) {
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

        func list() -> [ChargeScore] {
            var out: [ChargeScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeScoreStore() -> any ChargeScoreStore {
        return MemoryChargeScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeScoreStore: ChargeScoreStore {
        var inner: MemoryChargeScoreStore
        var cache: TTLCache<ChargeScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeScoreStore, cache: TTLCache<ChargeScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeScore? {
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

        func save(_ item: ChargeScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeScore] {
            return inner.list()
        }
    }

    static func newCachedChargeScoreStore(_ inner: MemoryChargeScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeScoreStore {
        return CachedChargeScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge scores. Empty fields match all.
    final class ChargeScoreQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeScore]) -> [ChargeScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeScores(_ store: any ChargeScoreStore, query: ChargeScoreQuery) -> [ChargeScore] {
        return query.apply(store.list())
    }
}
