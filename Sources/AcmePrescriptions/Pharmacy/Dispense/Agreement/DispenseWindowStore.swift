import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense windows by code.
    protocol DispenseWindowStore {
        func find(_ code: String) -> DispenseWindow?
        func save(_ item: DispenseWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseWindowStore: DispenseWindowStore {
        var items: [String: DispenseWindow]
        var order: [String]

        init(items: [String: DispenseWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseWindow) {
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

        func list() -> [DispenseWindow] {
            var out: [DispenseWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseWindowStore() -> any DispenseWindowStore {
        return MemoryDispenseWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseWindowStore: DispenseWindowStore {
        var inner: MemoryDispenseWindowStore
        var cache: TTLCache<DispenseWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseWindowStore, cache: TTLCache<DispenseWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseWindow? {
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

        func save(_ item: DispenseWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseWindow] {
            return inner.list()
        }
    }

    static func newCachedDispenseWindowStore(_ inner: MemoryDispenseWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseWindowStore {
        return CachedDispenseWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense windows. Empty fields match all.
    final class DispenseWindowQuery {
        var segment: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minScore: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseWindow) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseWindow]) -> [DispenseWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseWindows(_ store: any DispenseWindowStore, query: DispenseWindowQuery) -> [DispenseWindow] {
        return query.apply(store.list())
    }
}
