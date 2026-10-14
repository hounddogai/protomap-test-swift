import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap windows by code.
    protocol CareGapWindowStore {
        func find(_ code: String) -> CareGapWindow?
        func save(_ item: CareGapWindow)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapWindowStore: CareGapWindowStore {
        var items: [String: CareGapWindow]
        var order: [String]

        init(items: [String: CareGapWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapWindow) {
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

        func list() -> [CareGapWindow] {
            var out: [CareGapWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapWindowStore() -> any CareGapWindowStore {
        return MemoryCareGapWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapWindowStore: CareGapWindowStore {
        var inner: MemoryCareGapWindowStore
        var cache: TTLCache<CareGapWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapWindowStore, cache: TTLCache<CareGapWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapWindow? {
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

        func save(_ item: CareGapWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapWindow] {
            return inner.list()
        }
    }

    static func newCachedCareGapWindowStore(_ inner: MemoryCareGapWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapWindowStore {
        return CachedCareGapWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap windows. Empty fields match all.
    final class CareGapWindowQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapWindow]) -> [CareGapWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapWindows(_ store: any CareGapWindowStore, query: CareGapWindowQuery) -> [CareGapWindow] {
        return query.apply(store.list())
    }
}
