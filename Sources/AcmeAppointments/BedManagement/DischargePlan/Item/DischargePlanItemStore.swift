import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan items by code.
    protocol DischargePlanItemStore {
        func find(_ code: String) -> DischargePlanItem?
        func save(_ item: DischargePlanItem)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanItem]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanItemStore: DischargePlanItemStore {
        var items: [String: DischargePlanItem]
        var order: [String]

        init(items: [String: DischargePlanItem], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanItem? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanItem) {
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

        func list() -> [DischargePlanItem] {
            var out: [DischargePlanItem] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanItemStore() -> any DischargePlanItemStore {
        return MemoryDischargePlanItemStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanItemStore: DischargePlanItemStore {
        var inner: MemoryDischargePlanItemStore
        var cache: TTLCache<DischargePlanItem>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanItemStore, cache: TTLCache<DischargePlanItem>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanItem? {
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

        func save(_ item: DischargePlanItem) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanItem] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanItemStore(_ inner: MemoryDischargePlanItemStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanItemStore {
        return CachedDischargePlanItemStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan items. Empty fields match all.
    final class DischargePlanItemQuery {
        var ward: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanItem) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanItem]) -> [DischargePlanItem] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanItem) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanItems(_ store: any DischargePlanItemStore, query: DischargePlanItemQuery) -> [DischargePlanItem] {
        return query.apply(store.list())
    }
}
