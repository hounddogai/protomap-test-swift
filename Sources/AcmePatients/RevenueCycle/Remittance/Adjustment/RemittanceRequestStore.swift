import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance requests by code.
    protocol RemittanceRequestStore {
        func find(_ code: String) -> RemittanceRequest?
        func save(_ item: RemittanceRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceRequestStore: RemittanceRequestStore {
        var items: [String: RemittanceRequest]
        var order: [String]

        init(items: [String: RemittanceRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceRequest) {
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

        func list() -> [RemittanceRequest] {
            var out: [RemittanceRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceRequestStore() -> any RemittanceRequestStore {
        return MemoryRemittanceRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceRequestStore: RemittanceRequestStore {
        var inner: MemoryRemittanceRequestStore
        var cache: TTLCache<RemittanceRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceRequestStore, cache: TTLCache<RemittanceRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceRequest? {
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

        func save(_ item: RemittanceRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceRequest] {
            return inner.list()
        }
    }

    static func newCachedRemittanceRequestStore(_ inner: MemoryRemittanceRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceRequestStore {
        return CachedRemittanceRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance requests. Empty fields match all.
    final class RemittanceRequestQuery {
        var region: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceRequest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [RemittanceRequest]) -> [RemittanceRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceRequests(_ store: any RemittanceRequestStore, query: RemittanceRequestQuery) -> [RemittanceRequest] {
        return query.apply(store.list())
    }
}
