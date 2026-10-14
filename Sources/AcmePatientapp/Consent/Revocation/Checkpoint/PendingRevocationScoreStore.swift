import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending revocation scores by code.
    protocol PendingRevocationScoreStore {
        func find(_ code: String) -> PendingRevocationScore?
        func save(_ item: PendingRevocationScore)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRevocationScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRevocationScoreStore: PendingRevocationScoreStore {
        var items: [String: PendingRevocationScore]
        var order: [String]

        init(items: [String: PendingRevocationScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRevocationScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRevocationScore) {
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

        func list() -> [PendingRevocationScore] {
            var out: [PendingRevocationScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRevocationScoreStore() -> any PendingRevocationScoreStore {
        return MemoryPendingRevocationScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRevocationScoreStore: PendingRevocationScoreStore {
        var inner: MemoryPendingRevocationScoreStore
        var cache: TTLCache<PendingRevocationScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRevocationScoreStore, cache: TTLCache<PendingRevocationScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRevocationScore? {
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

        func save(_ item: PendingRevocationScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRevocationScore] {
            return inner.list()
        }
    }

    static func newCachedPendingRevocationScoreStore(_ inner: MemoryPendingRevocationScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRevocationScoreStore {
        return CachedPendingRevocationScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending revocation scores. Empty fields match all.
    final class PendingRevocationScoreQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRevocationScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRevocationScore]) -> [PendingRevocationScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRevocationScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRevocationScores(_ store: any PendingRevocationScoreStore, query: PendingRevocationScoreQuery) -> [PendingRevocationScore] {
        return query.apply(store.list())
    }
}
