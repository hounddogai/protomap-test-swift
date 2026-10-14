import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding windows by code.
    protocol RoundingWindowStore {
        func find(_ code: String) -> RoundingWindow?
        func save(_ item: RoundingWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingWindowStore: RoundingWindowStore {
        var items: [String: RoundingWindow]
        var order: [String]

        init(items: [String: RoundingWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingWindow) {
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

        func list() -> [RoundingWindow] {
            var out: [RoundingWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingWindowStore() -> any RoundingWindowStore {
        return MemoryRoundingWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingWindowStore: RoundingWindowStore {
        var inner: MemoryRoundingWindowStore
        var cache: TTLCache<RoundingWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingWindowStore, cache: TTLCache<RoundingWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingWindow? {
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

        func save(_ item: RoundingWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingWindow] {
            return inner.list()
        }
    }

    static func newCachedRoundingWindowStore(_ inner: MemoryRoundingWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingWindowStore {
        return CachedRoundingWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding windows. Empty fields match all.
    final class RoundingWindowQuery {
        var category: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minWeight: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingWindow) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingWindow]) -> [RoundingWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingWindows(_ store: any RoundingWindowStore, query: RoundingWindowQuery) -> [RoundingWindow] {
        return query.apply(store.list())
    }
}
