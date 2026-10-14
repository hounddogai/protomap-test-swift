import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps weighted transfer targets by code.
    protocol WeightedTransferTargetStore {
        func find(_ code: String) -> WeightedTransferTarget?
        func save(_ item: WeightedTransferTarget)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedTransferTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedTransferTargetStore: WeightedTransferTargetStore {
        var items: [String: WeightedTransferTarget]
        var order: [String]

        init(items: [String: WeightedTransferTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedTransferTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedTransferTarget) {
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

        func list() -> [WeightedTransferTarget] {
            var out: [WeightedTransferTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedTransferTargetStore() -> any WeightedTransferTargetStore {
        return MemoryWeightedTransferTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedTransferTargetStore: WeightedTransferTargetStore {
        var inner: MemoryWeightedTransferTargetStore
        var cache: TTLCache<WeightedTransferTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedTransferTargetStore, cache: TTLCache<WeightedTransferTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedTransferTarget? {
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

        func save(_ item: WeightedTransferTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedTransferTarget] {
            return inner.list()
        }
    }

    static func newCachedWeightedTransferTargetStore(_ inner: MemoryWeightedTransferTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedTransferTargetStore {
        return CachedWeightedTransferTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted transfer targets. Empty fields match all.
    final class WeightedTransferTargetQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedTransferTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [WeightedTransferTarget]) -> [WeightedTransferTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedTransferTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedTransferTargets(_ store: any WeightedTransferTargetStore, query: WeightedTransferTargetQuery) -> [WeightedTransferTarget] {
        return query.apply(store.list())
    }
}
