import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped risk score claims by code.
    protocol CappedRiskScoreClaimStore {
        func find(_ code: String) -> CappedRiskScoreClaim?
        func save(_ item: CappedRiskScoreClaim)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRiskScoreClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRiskScoreClaimStore: CappedRiskScoreClaimStore {
        var items: [String: CappedRiskScoreClaim]
        var order: [String]

        init(items: [String: CappedRiskScoreClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRiskScoreClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRiskScoreClaim) {
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

        func list() -> [CappedRiskScoreClaim] {
            var out: [CappedRiskScoreClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRiskScoreClaimStore() -> any CappedRiskScoreClaimStore {
        return MemoryCappedRiskScoreClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRiskScoreClaimStore: CappedRiskScoreClaimStore {
        var inner: MemoryCappedRiskScoreClaimStore
        var cache: TTLCache<CappedRiskScoreClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRiskScoreClaimStore, cache: TTLCache<CappedRiskScoreClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRiskScoreClaim? {
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

        func save(_ item: CappedRiskScoreClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRiskScoreClaim] {
            return inner.list()
        }
    }

    static func newCachedCappedRiskScoreClaimStore(_ inner: MemoryCappedRiskScoreClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRiskScoreClaimStore {
        return CachedCappedRiskScoreClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped risk score claims. Empty fields match all.
    final class CappedRiskScoreClaimQuery {
        var category: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRiskScoreClaim) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRiskScoreClaim]) -> [CappedRiskScoreClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRiskScoreClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRiskScoreClaims(_ store: any CappedRiskScoreClaimStore, query: CappedRiskScoreClaimQuery) -> [CappedRiskScoreClaim] {
        return query.apply(store.list())
    }
}
