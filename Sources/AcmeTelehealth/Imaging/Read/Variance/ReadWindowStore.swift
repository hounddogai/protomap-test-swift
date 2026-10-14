import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read windows by code.
    protocol ReadWindowStore {
        func find(_ code: String) -> ReadWindow?
        func save(_ item: ReadWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ReadWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadWindowStore: ReadWindowStore {
        var items: [String: ReadWindow]
        var order: [String]

        init(items: [String: ReadWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadWindow) {
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

        func list() -> [ReadWindow] {
            var out: [ReadWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadWindowStore() -> any ReadWindowStore {
        return MemoryReadWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadWindowStore: ReadWindowStore {
        var inner: MemoryReadWindowStore
        var cache: TTLCache<ReadWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadWindowStore, cache: TTLCache<ReadWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadWindow? {
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

        func save(_ item: ReadWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadWindow] {
            return inner.list()
        }
    }

    static func newCachedReadWindowStore(_ inner: MemoryReadWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadWindowStore {
        return CachedReadWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read windows. Empty fields match all.
    final class ReadWindowQuery {
        var region: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minBudget: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadWindow) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadWindow]) -> [ReadWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadWindows(_ store: any ReadWindowStore, query: ReadWindowQuery) -> [ReadWindow] {
        return query.apply(store.list())
    }
}
