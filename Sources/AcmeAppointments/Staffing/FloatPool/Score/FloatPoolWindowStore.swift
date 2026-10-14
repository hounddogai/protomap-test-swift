import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool windows by code.
    protocol FloatPoolWindowStore {
        func find(_ code: String) -> FloatPoolWindow?
        func save(_ item: FloatPoolWindow)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolWindowStore: FloatPoolWindowStore {
        var items: [String: FloatPoolWindow]
        var order: [String]

        init(items: [String: FloatPoolWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolWindow) {
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

        func list() -> [FloatPoolWindow] {
            var out: [FloatPoolWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolWindowStore() -> any FloatPoolWindowStore {
        return MemoryFloatPoolWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolWindowStore: FloatPoolWindowStore {
        var inner: MemoryFloatPoolWindowStore
        var cache: TTLCache<FloatPoolWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolWindowStore, cache: TTLCache<FloatPoolWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolWindow? {
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

        func save(_ item: FloatPoolWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolWindow] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolWindowStore(_ inner: MemoryFloatPoolWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolWindowStore {
        return CachedFloatPoolWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool windows. Empty fields match all.
    final class FloatPoolWindowQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolWindow) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolWindow]) -> [FloatPoolWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolWindows(_ store: any FloatPoolWindowStore, query: FloatPoolWindowQuery) -> [FloatPoolWindow] {
        return query.apply(store.list())
    }
}
