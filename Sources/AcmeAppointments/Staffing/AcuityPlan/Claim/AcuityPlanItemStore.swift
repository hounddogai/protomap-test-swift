import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan items by code.
    protocol AcuityPlanItemStore {
        func find(_ code: String) -> AcuityPlanItem?
        func save(_ item: AcuityPlanItem)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanItem]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanItemStore: AcuityPlanItemStore {
        var items: [String: AcuityPlanItem]
        var order: [String]

        init(items: [String: AcuityPlanItem], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanItem? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanItem) {
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

        func list() -> [AcuityPlanItem] {
            var out: [AcuityPlanItem] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanItemStore() -> any AcuityPlanItemStore {
        return MemoryAcuityPlanItemStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanItemStore: AcuityPlanItemStore {
        var inner: MemoryAcuityPlanItemStore
        var cache: TTLCache<AcuityPlanItem>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanItemStore, cache: TTLCache<AcuityPlanItem>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanItem? {
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

        func save(_ item: AcuityPlanItem) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanItem] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanItemStore(_ inner: MemoryAcuityPlanItemStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanItemStore {
        return CachedAcuityPlanItemStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan items. Empty fields match all.
    final class AcuityPlanItemQuery {
        var segment: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minPriority: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanItem) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [AcuityPlanItem]) -> [AcuityPlanItem] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanItem) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanItems(_ store: any AcuityPlanItemStore, query: AcuityPlanItemQuery) -> [AcuityPlanItem] {
        return query.apply(store.list())
    }
}
