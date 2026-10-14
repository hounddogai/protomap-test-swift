import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set thresholds by code.
    protocol OrderSetThresholdStore {
        func find(_ code: String) -> OrderSetThreshold?
        func save(_ item: OrderSetThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetThresholdStore: OrderSetThresholdStore {
        var items: [String: OrderSetThreshold]
        var order: [String]

        init(items: [String: OrderSetThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetThreshold) {
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

        func list() -> [OrderSetThreshold] {
            var out: [OrderSetThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetThresholdStore() -> any OrderSetThresholdStore {
        return MemoryOrderSetThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetThresholdStore: OrderSetThresholdStore {
        var inner: MemoryOrderSetThresholdStore
        var cache: TTLCache<OrderSetThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetThresholdStore, cache: TTLCache<OrderSetThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetThreshold? {
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

        func save(_ item: OrderSetThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetThreshold] {
            return inner.list()
        }
    }

    static func newCachedOrderSetThresholdStore(_ inner: MemoryOrderSetThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetThresholdStore {
        return CachedOrderSetThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set thresholds. Empty fields match all.
    final class OrderSetThresholdQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [OrderSetThreshold]) -> [OrderSetThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetThresholds(_ store: any OrderSetThresholdStore, query: OrderSetThresholdQuery) -> [OrderSetThreshold] {
        return query.apply(store.list())
    }
}
