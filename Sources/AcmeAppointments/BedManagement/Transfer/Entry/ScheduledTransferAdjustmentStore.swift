import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled transfer adjustments by code.
    protocol ScheduledTransferAdjustmentStore {
        func find(_ code: String) -> ScheduledTransferAdjustment?
        func save(_ item: ScheduledTransferAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledTransferAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledTransferAdjustmentStore: ScheduledTransferAdjustmentStore {
        var items: [String: ScheduledTransferAdjustment]
        var order: [String]

        init(items: [String: ScheduledTransferAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledTransferAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledTransferAdjustment) {
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

        func list() -> [ScheduledTransferAdjustment] {
            var out: [ScheduledTransferAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledTransferAdjustmentStore() -> any ScheduledTransferAdjustmentStore {
        return MemoryScheduledTransferAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledTransferAdjustmentStore: ScheduledTransferAdjustmentStore {
        var inner: MemoryScheduledTransferAdjustmentStore
        var cache: TTLCache<ScheduledTransferAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledTransferAdjustmentStore, cache: TTLCache<ScheduledTransferAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledTransferAdjustment? {
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

        func save(_ item: ScheduledTransferAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledTransferAdjustment] {
            return inner.list()
        }
    }

    static func newCachedScheduledTransferAdjustmentStore(_ inner: MemoryScheduledTransferAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledTransferAdjustmentStore {
        return CachedScheduledTransferAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled transfer adjustments. Empty fields match all.
    final class ScheduledTransferAdjustmentQuery {
        var channel: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledTransferAdjustment) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledTransferAdjustment]) -> [ScheduledTransferAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledTransferAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledTransferAdjustments(_ store: any ScheduledTransferAdjustmentStore, query: ScheduledTransferAdjustmentQuery) -> [ScheduledTransferAdjustment] {
        return query.apply(store.list())
    }
}
