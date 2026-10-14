import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol variances by code.
    protocol CareProtocolVarianceStore {
        func find(_ code: String) -> CareProtocolVariance?
        func save(_ item: CareProtocolVariance)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolVarianceStore: CareProtocolVarianceStore {
        var items: [String: CareProtocolVariance]
        var order: [String]

        init(items: [String: CareProtocolVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolVariance) {
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

        func list() -> [CareProtocolVariance] {
            var out: [CareProtocolVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolVarianceStore() -> any CareProtocolVarianceStore {
        return MemoryCareProtocolVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolVarianceStore: CareProtocolVarianceStore {
        var inner: MemoryCareProtocolVarianceStore
        var cache: TTLCache<CareProtocolVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolVarianceStore, cache: TTLCache<CareProtocolVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolVariance? {
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

        func save(_ item: CareProtocolVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolVariance] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolVarianceStore(_ inner: MemoryCareProtocolVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolVarianceStore {
        return CachedCareProtocolVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol variances. Empty fields match all.
    final class CareProtocolVarianceQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolVariance) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolVariance]) -> [CareProtocolVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolVariances(_ store: any CareProtocolVarianceStore, query: CareProtocolVarianceQuery) -> [CareProtocolVariance] {
        return query.apply(store.list())
    }
}
