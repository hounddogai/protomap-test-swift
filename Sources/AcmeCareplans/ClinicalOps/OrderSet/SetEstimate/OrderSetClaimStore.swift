import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set claims by code.
    protocol OrderSetClaimStore {
        func find(_ code: String) -> OrderSetClaim?
        func save(_ item: OrderSetClaim)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetClaimStore: OrderSetClaimStore {
        var items: [String: OrderSetClaim]
        var order: [String]

        init(items: [String: OrderSetClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetClaim) {
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

        func list() -> [OrderSetClaim] {
            var out: [OrderSetClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetClaimStore() -> any OrderSetClaimStore {
        return MemoryOrderSetClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetClaimStore: OrderSetClaimStore {
        var inner: MemoryOrderSetClaimStore
        var cache: TTLCache<OrderSetClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetClaimStore, cache: TTLCache<OrderSetClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetClaim? {
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

        func save(_ item: OrderSetClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetClaim] {
            return inner.list()
        }
    }

    static func newCachedOrderSetClaimStore(_ inner: MemoryOrderSetClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetClaimStore {
        return CachedOrderSetClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set claims. Empty fields match all.
    final class OrderSetClaimQuery {
        var channel: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVersion: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetClaim) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetClaim]) -> [OrderSetClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetClaims(_ store: any OrderSetClaimStore, query: OrderSetClaimQuery) -> [OrderSetClaim] {
        return query.apply(store.list())
    }
}
