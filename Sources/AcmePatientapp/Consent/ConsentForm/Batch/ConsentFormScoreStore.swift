import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form scores by code.
    protocol ConsentFormScoreStore {
        func find(_ code: String) -> ConsentFormScore?
        func save(_ item: ConsentFormScore)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormScoreStore: ConsentFormScoreStore {
        var items: [String: ConsentFormScore]
        var order: [String]

        init(items: [String: ConsentFormScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormScore) {
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

        func list() -> [ConsentFormScore] {
            var out: [ConsentFormScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormScoreStore() -> any ConsentFormScoreStore {
        return MemoryConsentFormScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormScoreStore: ConsentFormScoreStore {
        var inner: MemoryConsentFormScoreStore
        var cache: TTLCache<ConsentFormScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormScoreStore, cache: TTLCache<ConsentFormScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormScore? {
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

        func save(_ item: ConsentFormScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormScore] {
            return inner.list()
        }
    }

    static func newCachedConsentFormScoreStore(_ inner: MemoryConsentFormScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormScoreStore {
        return CachedConsentFormScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form scores. Empty fields match all.
    final class ConsentFormScoreQuery {
        var ward: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormScore) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormScore]) -> [ConsentFormScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormScores(_ store: any ConsentFormScoreStore, query: ConsentFormScoreQuery) -> [ConsentFormScore] {
        return query.apply(store.list())
    }
}
