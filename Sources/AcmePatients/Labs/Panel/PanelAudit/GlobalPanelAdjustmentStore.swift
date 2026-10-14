import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global panel adjustments by code.
    protocol GlobalPanelAdjustmentStore {
        func find(_ code: String) -> GlobalPanelAdjustment?
        func save(_ item: GlobalPanelAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalPanelAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalPanelAdjustmentStore: GlobalPanelAdjustmentStore {
        var items: [String: GlobalPanelAdjustment]
        var order: [String]

        init(items: [String: GlobalPanelAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalPanelAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalPanelAdjustment) {
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

        func list() -> [GlobalPanelAdjustment] {
            var out: [GlobalPanelAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalPanelAdjustmentStore() -> any GlobalPanelAdjustmentStore {
        return MemoryGlobalPanelAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalPanelAdjustmentStore: GlobalPanelAdjustmentStore {
        var inner: MemoryGlobalPanelAdjustmentStore
        var cache: TTLCache<GlobalPanelAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalPanelAdjustmentStore, cache: TTLCache<GlobalPanelAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalPanelAdjustment? {
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

        func save(_ item: GlobalPanelAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalPanelAdjustment] {
            return inner.list()
        }
    }

    static func newCachedGlobalPanelAdjustmentStore(_ inner: MemoryGlobalPanelAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalPanelAdjustmentStore {
        return CachedGlobalPanelAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global panel adjustments. Empty fields match all.
    final class GlobalPanelAdjustmentQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalPanelAdjustment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalPanelAdjustment]) -> [GlobalPanelAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalPanelAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalPanelAdjustments(_ store: any GlobalPanelAdjustmentStore, query: GlobalPanelAdjustmentQuery) -> [GlobalPanelAdjustment] {
        return query.apply(store.list())
    }
}
