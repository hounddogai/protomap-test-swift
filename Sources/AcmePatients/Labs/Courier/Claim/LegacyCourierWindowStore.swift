import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy courier windows by code.
    protocol LegacyCourierWindowStore {
        func find(_ code: String) -> LegacyCourierWindow?
        func save(_ item: LegacyCourierWindow)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCourierWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCourierWindowStore: LegacyCourierWindowStore {
        var items: [String: LegacyCourierWindow]
        var order: [String]

        init(items: [String: LegacyCourierWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCourierWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCourierWindow) {
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

        func list() -> [LegacyCourierWindow] {
            var out: [LegacyCourierWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCourierWindowStore() -> any LegacyCourierWindowStore {
        return MemoryLegacyCourierWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCourierWindowStore: LegacyCourierWindowStore {
        var inner: MemoryLegacyCourierWindowStore
        var cache: TTLCache<LegacyCourierWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCourierWindowStore, cache: TTLCache<LegacyCourierWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCourierWindow? {
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

        func save(_ item: LegacyCourierWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCourierWindow] {
            return inner.list()
        }
    }

    static func newCachedLegacyCourierWindowStore(_ inner: MemoryLegacyCourierWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCourierWindowStore {
        return CachedLegacyCourierWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy courier windows. Empty fields match all.
    final class LegacyCourierWindowQuery {
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

        func matches(_ item: LegacyCourierWindow) -> Bool {
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

        func apply(_ items: [LegacyCourierWindow]) -> [LegacyCourierWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCourierWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCourierWindows(_ store: any LegacyCourierWindowStore, query: LegacyCourierWindowQuery) -> [LegacyCourierWindow] {
        return query.apply(store.list())
    }
}
