import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer adjustments by code.
    protocol TransferAdjustmentStore {
        func find(_ code: String) -> TransferAdjustment?
        func save(_ item: TransferAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [TransferAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferAdjustmentStore: TransferAdjustmentStore {
        var items: [String: TransferAdjustment]
        var order: [String]

        init(items: [String: TransferAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferAdjustment) {
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

        func list() -> [TransferAdjustment] {
            var out: [TransferAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferAdjustmentStore() -> any TransferAdjustmentStore {
        return MemoryTransferAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferAdjustmentStore: TransferAdjustmentStore {
        var inner: MemoryTransferAdjustmentStore
        var cache: TTLCache<TransferAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferAdjustmentStore, cache: TTLCache<TransferAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferAdjustment? {
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

        func save(_ item: TransferAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferAdjustment] {
            return inner.list()
        }
    }

    static func newCachedTransferAdjustmentStore(_ inner: MemoryTransferAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferAdjustmentStore {
        return CachedTransferAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer adjustments. Empty fields match all.
    final class TransferAdjustmentQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferAdjustment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferAdjustment]) -> [TransferAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferAdjustments(_ store: any TransferAdjustmentStore, query: TransferAdjustmentQuery) -> [TransferAdjustment] {
        return query.apply(store.list())
    }
}
