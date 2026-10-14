import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set overrides by code.
    protocol OrderSetOverrideStore {
        func find(_ code: String) -> OrderSetOverride?
        func save(_ item: OrderSetOverride)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetOverrideStore: OrderSetOverrideStore {
        var items: [String: OrderSetOverride]
        var order: [String]

        init(items: [String: OrderSetOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetOverride) {
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

        func list() -> [OrderSetOverride] {
            var out: [OrderSetOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetOverrideStore() -> any OrderSetOverrideStore {
        return MemoryOrderSetOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetOverrideStore: OrderSetOverrideStore {
        var inner: MemoryOrderSetOverrideStore
        var cache: TTLCache<OrderSetOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetOverrideStore, cache: TTLCache<OrderSetOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetOverride? {
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

        func save(_ item: OrderSetOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetOverride] {
            return inner.list()
        }
    }

    static func newCachedOrderSetOverrideStore(_ inner: MemoryOrderSetOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetOverrideStore {
        return CachedOrderSetOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set overrides. Empty fields match all.
    final class OrderSetOverrideQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetOverride]) -> [OrderSetOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetOverrides(_ store: any OrderSetOverrideStore, query: OrderSetOverrideQuery) -> [OrderSetOverride] {
        return query.apply(store.list())
    }
}
