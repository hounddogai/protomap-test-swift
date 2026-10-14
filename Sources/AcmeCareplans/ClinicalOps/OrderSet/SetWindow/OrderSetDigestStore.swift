import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set digests by code.
    protocol OrderSetDigestStore {
        func find(_ code: String) -> OrderSetDigest?
        func save(_ item: OrderSetDigest)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetDigestStore: OrderSetDigestStore {
        var items: [String: OrderSetDigest]
        var order: [String]

        init(items: [String: OrderSetDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetDigest) {
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

        func list() -> [OrderSetDigest] {
            var out: [OrderSetDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetDigestStore() -> any OrderSetDigestStore {
        return MemoryOrderSetDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetDigestStore: OrderSetDigestStore {
        var inner: MemoryOrderSetDigestStore
        var cache: TTLCache<OrderSetDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetDigestStore, cache: TTLCache<OrderSetDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetDigest? {
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

        func save(_ item: OrderSetDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetDigest] {
            return inner.list()
        }
    }

    static func newCachedOrderSetDigestStore(_ inner: MemoryOrderSetDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetDigestStore {
        return CachedOrderSetDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set digests. Empty fields match all.
    final class OrderSetDigestQuery {
        var region: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetDigest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetDigest]) -> [OrderSetDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetDigests(_ store: any OrderSetDigestStore, query: OrderSetDigestQuery) -> [OrderSetDigest] {
        return query.apply(store.list())
    }
}
