import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen windows by code.
    protocol SpecimenWindowStore {
        func find(_ code: String) -> SpecimenWindow?
        func save(_ item: SpecimenWindow)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenWindowStore: SpecimenWindowStore {
        var items: [String: SpecimenWindow]
        var order: [String]

        init(items: [String: SpecimenWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenWindow) {
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

        func list() -> [SpecimenWindow] {
            var out: [SpecimenWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenWindowStore() -> any SpecimenWindowStore {
        return MemorySpecimenWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenWindowStore: SpecimenWindowStore {
        var inner: MemorySpecimenWindowStore
        var cache: TTLCache<SpecimenWindow>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenWindowStore, cache: TTLCache<SpecimenWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenWindow? {
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

        func save(_ item: SpecimenWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenWindow] {
            return inner.list()
        }
    }

    static func newCachedSpecimenWindowStore(_ inner: MemorySpecimenWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenWindowStore {
        return CachedSpecimenWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen windows. Empty fields match all.
    final class SpecimenWindowQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SpecimenWindow]) -> [SpecimenWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenWindows(_ store: any SpecimenWindowStore, query: SpecimenWindowQuery) -> [SpecimenWindow] {
        return query.apply(store.list())
    }
}
