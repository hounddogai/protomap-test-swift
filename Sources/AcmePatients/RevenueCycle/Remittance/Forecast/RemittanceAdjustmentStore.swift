import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance adjustments by code.
    protocol RemittanceAdjustmentStore {
        func find(_ code: String) -> RemittanceAdjustment?
        func save(_ item: RemittanceAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceAdjustmentStore: RemittanceAdjustmentStore {
        var items: [String: RemittanceAdjustment]
        var order: [String]

        init(items: [String: RemittanceAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceAdjustment) {
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

        func list() -> [RemittanceAdjustment] {
            var out: [RemittanceAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceAdjustmentStore() -> any RemittanceAdjustmentStore {
        return MemoryRemittanceAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceAdjustmentStore: RemittanceAdjustmentStore {
        var inner: MemoryRemittanceAdjustmentStore
        var cache: TTLCache<RemittanceAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceAdjustmentStore, cache: TTLCache<RemittanceAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceAdjustment? {
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

        func save(_ item: RemittanceAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceAdjustment] {
            return inner.list()
        }
    }

    static func newCachedRemittanceAdjustmentStore(_ inner: MemoryRemittanceAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceAdjustmentStore {
        return CachedRemittanceAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance adjustments. Empty fields match all.
    final class RemittanceAdjustmentQuery {
        var segment: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minRate: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceAdjustment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [RemittanceAdjustment]) -> [RemittanceAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceAdjustments(_ store: any RemittanceAdjustmentStore, query: RemittanceAdjustmentQuery) -> [RemittanceAdjustment] {
        return query.apply(store.list())
    }
}
