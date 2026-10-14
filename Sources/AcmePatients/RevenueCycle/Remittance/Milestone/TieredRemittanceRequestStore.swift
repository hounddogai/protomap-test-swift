import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered remittance requests by code.
    protocol TieredRemittanceRequestStore {
        func find(_ code: String) -> TieredRemittanceRequest?
        func save(_ item: TieredRemittanceRequest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRemittanceRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRemittanceRequestStore: TieredRemittanceRequestStore {
        var items: [String: TieredRemittanceRequest]
        var order: [String]

        init(items: [String: TieredRemittanceRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRemittanceRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRemittanceRequest) {
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

        func list() -> [TieredRemittanceRequest] {
            var out: [TieredRemittanceRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRemittanceRequestStore() -> any TieredRemittanceRequestStore {
        return MemoryTieredRemittanceRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRemittanceRequestStore: TieredRemittanceRequestStore {
        var inner: MemoryTieredRemittanceRequestStore
        var cache: TTLCache<TieredRemittanceRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRemittanceRequestStore, cache: TTLCache<TieredRemittanceRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRemittanceRequest? {
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

        func save(_ item: TieredRemittanceRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRemittanceRequest] {
            return inner.list()
        }
    }

    static func newCachedTieredRemittanceRequestStore(_ inner: MemoryTieredRemittanceRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRemittanceRequestStore {
        return CachedTieredRemittanceRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered remittance requests. Empty fields match all.
    final class TieredRemittanceRequestQuery {
        var region: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRemittanceRequest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRemittanceRequest]) -> [TieredRemittanceRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRemittanceRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRemittanceRequests(_ store: any TieredRemittanceRequestStore, query: TieredRemittanceRequestQuery) -> [TieredRemittanceRequest] {
        return query.apply(store.list())
    }
}
