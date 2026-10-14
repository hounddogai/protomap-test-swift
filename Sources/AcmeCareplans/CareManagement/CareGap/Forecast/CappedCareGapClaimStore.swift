import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped care gap claims by code.
    protocol CappedCareGapClaimStore {
        func find(_ code: String) -> CappedCareGapClaim?
        func save(_ item: CappedCareGapClaim)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCareGapClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCareGapClaimStore: CappedCareGapClaimStore {
        var items: [String: CappedCareGapClaim]
        var order: [String]

        init(items: [String: CappedCareGapClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCareGapClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCareGapClaim) {
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

        func list() -> [CappedCareGapClaim] {
            var out: [CappedCareGapClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCareGapClaimStore() -> any CappedCareGapClaimStore {
        return MemoryCappedCareGapClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCareGapClaimStore: CappedCareGapClaimStore {
        var inner: MemoryCappedCareGapClaimStore
        var cache: TTLCache<CappedCareGapClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCareGapClaimStore, cache: TTLCache<CappedCareGapClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCareGapClaim? {
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

        func save(_ item: CappedCareGapClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCareGapClaim] {
            return inner.list()
        }
    }

    static func newCachedCappedCareGapClaimStore(_ inner: MemoryCappedCareGapClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCareGapClaimStore {
        return CachedCappedCareGapClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped care gap claims. Empty fields match all.
    final class CappedCareGapClaimQuery {
        var locale: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCareGapClaim) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCareGapClaim]) -> [CappedCareGapClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCareGapClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCareGapClaims(_ store: any CappedCareGapClaimStore, query: CappedCareGapClaimQuery) -> [CappedCareGapClaim] {
        return query.apply(store.list())
    }
}
