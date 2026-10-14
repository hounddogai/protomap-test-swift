import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual discharge plan items by code.
    protocol ManualDischargePlanItemStore {
        func find(_ code: String) -> ManualDischargePlanItem?
        func save(_ item: ManualDischargePlanItem)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDischargePlanItem]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDischargePlanItemStore: ManualDischargePlanItemStore {
        var items: [String: ManualDischargePlanItem]
        var order: [String]

        init(items: [String: ManualDischargePlanItem], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDischargePlanItem? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDischargePlanItem) {
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

        func list() -> [ManualDischargePlanItem] {
            var out: [ManualDischargePlanItem] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDischargePlanItemStore() -> any ManualDischargePlanItemStore {
        return MemoryManualDischargePlanItemStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDischargePlanItemStore: ManualDischargePlanItemStore {
        var inner: MemoryManualDischargePlanItemStore
        var cache: TTLCache<ManualDischargePlanItem>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDischargePlanItemStore, cache: TTLCache<ManualDischargePlanItem>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDischargePlanItem? {
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

        func save(_ item: ManualDischargePlanItem) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDischargePlanItem] {
            return inner.list()
        }
    }

    static func newCachedManualDischargePlanItemStore(_ inner: MemoryManualDischargePlanItemStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDischargePlanItemStore {
        return CachedManualDischargePlanItemStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual discharge plan items. Empty fields match all.
    final class ManualDischargePlanItemQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDischargePlanItem) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ManualDischargePlanItem]) -> [ManualDischargePlanItem] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDischargePlanItem) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDischargePlanItems(_ store: any ManualDischargePlanItemStore, query: ManualDischargePlanItemQuery) -> [ManualDischargePlanItem] {
        return query.apply(store.list())
    }
}
