import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending care protocol variances by code.
    protocol PendingCareProtocolVarianceStore {
        func find(_ code: String) -> PendingCareProtocolVariance?
        func save(_ item: PendingCareProtocolVariance)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCareProtocolVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCareProtocolVarianceStore: PendingCareProtocolVarianceStore {
        var items: [String: PendingCareProtocolVariance]
        var order: [String]

        init(items: [String: PendingCareProtocolVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCareProtocolVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCareProtocolVariance) {
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

        func list() -> [PendingCareProtocolVariance] {
            var out: [PendingCareProtocolVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCareProtocolVarianceStore() -> any PendingCareProtocolVarianceStore {
        return MemoryPendingCareProtocolVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCareProtocolVarianceStore: PendingCareProtocolVarianceStore {
        var inner: MemoryPendingCareProtocolVarianceStore
        var cache: TTLCache<PendingCareProtocolVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCareProtocolVarianceStore, cache: TTLCache<PendingCareProtocolVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCareProtocolVariance? {
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

        func save(_ item: PendingCareProtocolVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCareProtocolVariance] {
            return inner.list()
        }
    }

    static func newCachedPendingCareProtocolVarianceStore(_ inner: MemoryPendingCareProtocolVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCareProtocolVarianceStore {
        return CachedPendingCareProtocolVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending care protocol variances. Empty fields match all.
    final class PendingCareProtocolVarianceQuery {
        var region: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCareProtocolVariance) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [PendingCareProtocolVariance]) -> [PendingCareProtocolVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCareProtocolVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCareProtocolVariances(_ store: any PendingCareProtocolVarianceStore, query: PendingCareProtocolVarianceQuery) -> [PendingCareProtocolVariance] {
        return query.apply(store.list())
    }
}
