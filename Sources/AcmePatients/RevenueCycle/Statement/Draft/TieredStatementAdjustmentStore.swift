import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered statement adjustments by code.
    protocol TieredStatementAdjustmentStore {
        func find(_ code: String) -> TieredStatementAdjustment?
        func save(_ item: TieredStatementAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredStatementAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredStatementAdjustmentStore: TieredStatementAdjustmentStore {
        var items: [String: TieredStatementAdjustment]
        var order: [String]

        init(items: [String: TieredStatementAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredStatementAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredStatementAdjustment) {
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

        func list() -> [TieredStatementAdjustment] {
            var out: [TieredStatementAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredStatementAdjustmentStore() -> any TieredStatementAdjustmentStore {
        return MemoryTieredStatementAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredStatementAdjustmentStore: TieredStatementAdjustmentStore {
        var inner: MemoryTieredStatementAdjustmentStore
        var cache: TTLCache<TieredStatementAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredStatementAdjustmentStore, cache: TTLCache<TieredStatementAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredStatementAdjustment? {
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

        func save(_ item: TieredStatementAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredStatementAdjustment] {
            return inner.list()
        }
    }

    static func newCachedTieredStatementAdjustmentStore(_ inner: MemoryTieredStatementAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredStatementAdjustmentStore {
        return CachedTieredStatementAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered statement adjustments. Empty fields match all.
    final class TieredStatementAdjustmentQuery {
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

        func matches(_ item: TieredStatementAdjustment) -> Bool {
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

        func apply(_ items: [TieredStatementAdjustment]) -> [TieredStatementAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredStatementAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredStatementAdjustments(_ store: any TieredStatementAdjustmentStore, query: TieredStatementAdjustmentQuery) -> [TieredStatementAdjustment] {
        return query.apply(store.list())
    }
}
