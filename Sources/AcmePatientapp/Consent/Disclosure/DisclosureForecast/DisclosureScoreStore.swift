import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure scores by code.
    protocol DisclosureScoreStore {
        func find(_ code: String) -> DisclosureScore?
        func save(_ item: DisclosureScore)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureScoreStore: DisclosureScoreStore {
        var items: [String: DisclosureScore]
        var order: [String]

        init(items: [String: DisclosureScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureScore) {
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

        func list() -> [DisclosureScore] {
            var out: [DisclosureScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureScoreStore() -> any DisclosureScoreStore {
        return MemoryDisclosureScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureScoreStore: DisclosureScoreStore {
        var inner: MemoryDisclosureScoreStore
        var cache: TTLCache<DisclosureScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureScoreStore, cache: TTLCache<DisclosureScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureScore? {
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

        func save(_ item: DisclosureScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureScore] {
            return inner.list()
        }
    }

    static func newCachedDisclosureScoreStore(_ inner: MemoryDisclosureScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureScoreStore {
        return CachedDisclosureScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure scores. Empty fields match all.
    final class DisclosureScoreQuery {
        var ward: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureScore) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureScore]) -> [DisclosureScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureScores(_ store: any DisclosureScoreStore, query: DisclosureScoreQuery) -> [DisclosureScore] {
        return query.apply(store.list())
    }
}
