import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance scores by code.
    protocol RemittanceScoreStore {
        func find(_ code: String) -> RemittanceScore?
        func save(_ item: RemittanceScore)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceScoreStore: RemittanceScoreStore {
        var items: [String: RemittanceScore]
        var order: [String]

        init(items: [String: RemittanceScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceScore) {
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

        func list() -> [RemittanceScore] {
            var out: [RemittanceScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceScoreStore() -> any RemittanceScoreStore {
        return MemoryRemittanceScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceScoreStore: RemittanceScoreStore {
        var inner: MemoryRemittanceScoreStore
        var cache: TTLCache<RemittanceScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceScoreStore, cache: TTLCache<RemittanceScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceScore? {
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

        func save(_ item: RemittanceScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceScore] {
            return inner.list()
        }
    }

    static func newCachedRemittanceScoreStore(_ inner: MemoryRemittanceScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceScoreStore {
        return CachedRemittanceScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance scores. Empty fields match all.
    final class RemittanceScoreQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceScore) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceScore]) -> [RemittanceScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceScores(_ store: any RemittanceScoreStore, query: RemittanceScoreQuery) -> [RemittanceScore] {
        return query.apply(store.list())
    }
}
