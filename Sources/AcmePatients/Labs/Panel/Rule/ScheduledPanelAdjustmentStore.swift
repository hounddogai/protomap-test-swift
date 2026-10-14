import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled panel adjustments by code.
    protocol ScheduledPanelAdjustmentStore {
        func find(_ code: String) -> ScheduledPanelAdjustment?
        func save(_ item: ScheduledPanelAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledPanelAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledPanelAdjustmentStore: ScheduledPanelAdjustmentStore {
        var items: [String: ScheduledPanelAdjustment]
        var order: [String]

        init(items: [String: ScheduledPanelAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledPanelAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledPanelAdjustment) {
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

        func list() -> [ScheduledPanelAdjustment] {
            var out: [ScheduledPanelAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledPanelAdjustmentStore() -> any ScheduledPanelAdjustmentStore {
        return MemoryScheduledPanelAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledPanelAdjustmentStore: ScheduledPanelAdjustmentStore {
        var inner: MemoryScheduledPanelAdjustmentStore
        var cache: TTLCache<ScheduledPanelAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledPanelAdjustmentStore, cache: TTLCache<ScheduledPanelAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledPanelAdjustment? {
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

        func save(_ item: ScheduledPanelAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledPanelAdjustment] {
            return inner.list()
        }
    }

    static func newCachedScheduledPanelAdjustmentStore(_ inner: MemoryScheduledPanelAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledPanelAdjustmentStore {
        return CachedScheduledPanelAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled panel adjustments. Empty fields match all.
    final class ScheduledPanelAdjustmentQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledPanelAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledPanelAdjustment]) -> [ScheduledPanelAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledPanelAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledPanelAdjustments(_ store: any ScheduledPanelAdjustmentStore, query: ScheduledPanelAdjustmentQuery) -> [ScheduledPanelAdjustment] {
        return query.apply(store.list())
    }
}
