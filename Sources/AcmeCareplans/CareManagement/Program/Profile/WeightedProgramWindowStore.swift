import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted program windows by code.
    protocol WeightedProgramWindowStore {
        func find(_ code: String) -> WeightedProgramWindow?
        func save(_ item: WeightedProgramWindow)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedProgramWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedProgramWindowStore: WeightedProgramWindowStore {
        var items: [String: WeightedProgramWindow]
        var order: [String]

        init(items: [String: WeightedProgramWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedProgramWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedProgramWindow) {
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

        func list() -> [WeightedProgramWindow] {
            var out: [WeightedProgramWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedProgramWindowStore() -> any WeightedProgramWindowStore {
        return MemoryWeightedProgramWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedProgramWindowStore: WeightedProgramWindowStore {
        var inner: MemoryWeightedProgramWindowStore
        var cache: TTLCache<WeightedProgramWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedProgramWindowStore, cache: TTLCache<WeightedProgramWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedProgramWindow? {
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

        func save(_ item: WeightedProgramWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedProgramWindow] {
            return inner.list()
        }
    }

    static func newCachedWeightedProgramWindowStore(_ inner: MemoryWeightedProgramWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedProgramWindowStore {
        return CachedWeightedProgramWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted program windows. Empty fields match all.
    final class WeightedProgramWindowQuery {
        var locale: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minPriority: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedProgramWindow) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [WeightedProgramWindow]) -> [WeightedProgramWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedProgramWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedProgramWindows(_ store: any WeightedProgramWindowStore, query: WeightedProgramWindowQuery) -> [WeightedProgramWindow] {
        return query.apply(store.list())
    }
}
