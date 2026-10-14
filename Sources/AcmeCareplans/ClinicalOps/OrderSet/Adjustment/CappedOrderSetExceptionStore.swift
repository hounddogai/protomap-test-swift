import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped order set exceptions by code.
    protocol CappedOrderSetExceptionStore {
        func find(_ code: String) -> CappedOrderSetException?
        func save(_ item: CappedOrderSetException)
        func remove(_ code: String) -> Bool
        func list() -> [CappedOrderSetException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedOrderSetExceptionStore: CappedOrderSetExceptionStore {
        var items: [String: CappedOrderSetException]
        var order: [String]

        init(items: [String: CappedOrderSetException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedOrderSetException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedOrderSetException) {
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

        func list() -> [CappedOrderSetException] {
            var out: [CappedOrderSetException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedOrderSetExceptionStore() -> any CappedOrderSetExceptionStore {
        return MemoryCappedOrderSetExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedOrderSetExceptionStore: CappedOrderSetExceptionStore {
        var inner: MemoryCappedOrderSetExceptionStore
        var cache: TTLCache<CappedOrderSetException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedOrderSetExceptionStore, cache: TTLCache<CappedOrderSetException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedOrderSetException? {
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

        func save(_ item: CappedOrderSetException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedOrderSetException] {
            return inner.list()
        }
    }

    static func newCachedCappedOrderSetExceptionStore(_ inner: MemoryCappedOrderSetExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedOrderSetExceptionStore {
        return CachedCappedOrderSetExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped order set exceptions. Empty fields match all.
    final class CappedOrderSetExceptionQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedOrderSetException) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedOrderSetException]) -> [CappedOrderSetException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedOrderSetException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedOrderSetExceptions(_ store: any CappedOrderSetExceptionStore, query: CappedOrderSetExceptionQuery) -> [CappedOrderSetException] {
        return query.apply(store.list())
    }
}
