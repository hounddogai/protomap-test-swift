import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default discharge plan windows by code.
    protocol DefaultDischargePlanWindowStore {
        func find(_ code: String) -> DefaultDischargePlanWindow?
        func save(_ item: DefaultDischargePlanWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultDischargePlanWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultDischargePlanWindowStore: DefaultDischargePlanWindowStore {
        var items: [String: DefaultDischargePlanWindow]
        var order: [String]

        init(items: [String: DefaultDischargePlanWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultDischargePlanWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultDischargePlanWindow) {
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

        func list() -> [DefaultDischargePlanWindow] {
            var out: [DefaultDischargePlanWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultDischargePlanWindowStore() -> any DefaultDischargePlanWindowStore {
        return MemoryDefaultDischargePlanWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultDischargePlanWindowStore: DefaultDischargePlanWindowStore {
        var inner: MemoryDefaultDischargePlanWindowStore
        var cache: TTLCache<DefaultDischargePlanWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultDischargePlanWindowStore, cache: TTLCache<DefaultDischargePlanWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultDischargePlanWindow? {
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

        func save(_ item: DefaultDischargePlanWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultDischargePlanWindow] {
            return inner.list()
        }
    }

    static func newCachedDefaultDischargePlanWindowStore(_ inner: MemoryDefaultDischargePlanWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultDischargePlanWindowStore {
        return CachedDefaultDischargePlanWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default discharge plan windows. Empty fields match all.
    final class DefaultDischargePlanWindowQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultDischargePlanWindow) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultDischargePlanWindow]) -> [DefaultDischargePlanWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultDischargePlanWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultDischargePlanWindows(_ store: any DefaultDischargePlanWindowStore, query: DefaultDischargePlanWindowQuery) -> [DefaultDischargePlanWindow] {
        return query.apply(store.list())
    }
}
