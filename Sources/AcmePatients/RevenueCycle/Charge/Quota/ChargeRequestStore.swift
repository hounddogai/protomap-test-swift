import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge requests by code.
    protocol ChargeRequestStore {
        func find(_ code: String) -> ChargeRequest?
        func save(_ item: ChargeRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeRequestStore: ChargeRequestStore {
        var items: [String: ChargeRequest]
        var order: [String]

        init(items: [String: ChargeRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeRequest) {
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

        func list() -> [ChargeRequest] {
            var out: [ChargeRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeRequestStore() -> any ChargeRequestStore {
        return MemoryChargeRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeRequestStore: ChargeRequestStore {
        var inner: MemoryChargeRequestStore
        var cache: TTLCache<ChargeRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeRequestStore, cache: TTLCache<ChargeRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeRequest? {
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

        func save(_ item: ChargeRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeRequest] {
            return inner.list()
        }
    }

    static func newCachedChargeRequestStore(_ inner: MemoryChargeRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeRequestStore {
        return CachedChargeRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge requests. Empty fields match all.
    final class ChargeRequestQuery {
        var channel: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minAmount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeRequest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeRequest]) -> [ChargeRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeRequests(_ store: any ChargeRequestStore, query: ChargeRequestQuery) -> [ChargeRequest] {
        return query.apply(store.list())
    }
}
