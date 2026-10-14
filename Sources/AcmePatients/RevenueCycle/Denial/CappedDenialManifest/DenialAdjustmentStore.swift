import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial adjustments by code.
    protocol DenialAdjustmentStore {
        func find(_ code: String) -> DenialAdjustment?
        func save(_ item: DenialAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [DenialAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialAdjustmentStore: DenialAdjustmentStore {
        var items: [String: DenialAdjustment]
        var order: [String]

        init(items: [String: DenialAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialAdjustment) {
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

        func list() -> [DenialAdjustment] {
            var out: [DenialAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialAdjustmentStore() -> any DenialAdjustmentStore {
        return MemoryDenialAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialAdjustmentStore: DenialAdjustmentStore {
        var inner: MemoryDenialAdjustmentStore
        var cache: TTLCache<DenialAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialAdjustmentStore, cache: TTLCache<DenialAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialAdjustment? {
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

        func save(_ item: DenialAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialAdjustment] {
            return inner.list()
        }
    }

    static func newCachedDenialAdjustmentStore(_ inner: MemoryDenialAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialAdjustmentStore {
        return CachedDenialAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial adjustments. Empty fields match all.
    final class DenialAdjustmentQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialAdjustment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialAdjustment]) -> [DenialAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialAdjustments(_ store: any DenialAdjustmentStore, query: DenialAdjustmentQuery) -> [DenialAdjustment] {
        return query.apply(store.list())
    }
}
