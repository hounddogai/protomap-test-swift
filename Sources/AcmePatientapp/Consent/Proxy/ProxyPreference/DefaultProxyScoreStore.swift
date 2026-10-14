import AcmePlatform
import Foundation

extension Consent {
    /// Keeps default proxy scores by code.
    protocol DefaultProxyScoreStore {
        func find(_ code: String) -> DefaultProxyScore?
        func save(_ item: DefaultProxyScore)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultProxyScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultProxyScoreStore: DefaultProxyScoreStore {
        var items: [String: DefaultProxyScore]
        var order: [String]

        init(items: [String: DefaultProxyScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultProxyScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultProxyScore) {
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

        func list() -> [DefaultProxyScore] {
            var out: [DefaultProxyScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultProxyScoreStore() -> any DefaultProxyScoreStore {
        return MemoryDefaultProxyScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultProxyScoreStore: DefaultProxyScoreStore {
        var inner: MemoryDefaultProxyScoreStore
        var cache: TTLCache<DefaultProxyScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultProxyScoreStore, cache: TTLCache<DefaultProxyScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultProxyScore? {
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

        func save(_ item: DefaultProxyScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultProxyScore] {
            return inner.list()
        }
    }

    static func newCachedDefaultProxyScoreStore(_ inner: MemoryDefaultProxyScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultProxyScoreStore {
        return CachedDefaultProxyScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default proxy scores. Empty fields match all.
    final class DefaultProxyScoreQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultProxyScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultProxyScore]) -> [DefaultProxyScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultProxyScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultProxyScores(_ store: any DefaultProxyScoreStore, query: DefaultProxyScoreQuery) -> [DefaultProxyScore] {
        return query.apply(store.list())
    }
}
