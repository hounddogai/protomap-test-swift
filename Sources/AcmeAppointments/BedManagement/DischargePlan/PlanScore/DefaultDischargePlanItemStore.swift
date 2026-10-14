import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default discharge plan items by code.
    protocol DefaultDischargePlanItemStore {
        func find(_ code: String) -> DefaultDischargePlanItem?
        func save(_ item: DefaultDischargePlanItem)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultDischargePlanItem]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultDischargePlanItemStore: DefaultDischargePlanItemStore {
        var items: [String: DefaultDischargePlanItem]
        var order: [String]

        init(items: [String: DefaultDischargePlanItem], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultDischargePlanItem? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultDischargePlanItem) {
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

        func list() -> [DefaultDischargePlanItem] {
            var out: [DefaultDischargePlanItem] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultDischargePlanItemStore() -> any DefaultDischargePlanItemStore {
        return MemoryDefaultDischargePlanItemStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultDischargePlanItemStore: DefaultDischargePlanItemStore {
        var inner: MemoryDefaultDischargePlanItemStore
        var cache: TTLCache<DefaultDischargePlanItem>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultDischargePlanItemStore, cache: TTLCache<DefaultDischargePlanItem>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultDischargePlanItem? {
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

        func save(_ item: DefaultDischargePlanItem) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultDischargePlanItem] {
            return inner.list()
        }
    }

    static func newCachedDefaultDischargePlanItemStore(_ inner: MemoryDefaultDischargePlanItemStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultDischargePlanItemStore {
        return CachedDefaultDischargePlanItemStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default discharge plan items. Empty fields match all.
    final class DefaultDischargePlanItemQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultDischargePlanItem) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultDischargePlanItem]) -> [DefaultDischargePlanItem] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultDischargePlanItem) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultDischargePlanItems(_ store: any DefaultDischargePlanItemStore, query: DefaultDischargePlanItemQuery) -> [DefaultDischargePlanItem] {
        return query.apply(store.list())
    }
}
