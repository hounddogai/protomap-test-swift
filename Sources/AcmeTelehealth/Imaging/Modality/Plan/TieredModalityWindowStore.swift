import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered modality windows by code.
    protocol TieredModalityWindowStore {
        func find(_ code: String) -> TieredModalityWindow?
        func save(_ item: TieredModalityWindow)
        func remove(_ code: String) -> Bool
        func list() -> [TieredModalityWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredModalityWindowStore: TieredModalityWindowStore {
        var items: [String: TieredModalityWindow]
        var order: [String]

        init(items: [String: TieredModalityWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredModalityWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredModalityWindow) {
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

        func list() -> [TieredModalityWindow] {
            var out: [TieredModalityWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredModalityWindowStore() -> any TieredModalityWindowStore {
        return MemoryTieredModalityWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredModalityWindowStore: TieredModalityWindowStore {
        var inner: MemoryTieredModalityWindowStore
        var cache: TTLCache<TieredModalityWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredModalityWindowStore, cache: TTLCache<TieredModalityWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredModalityWindow? {
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

        func save(_ item: TieredModalityWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredModalityWindow] {
            return inner.list()
        }
    }

    static func newCachedTieredModalityWindowStore(_ inner: MemoryTieredModalityWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredModalityWindowStore {
        return CachedTieredModalityWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered modality windows. Empty fields match all.
    final class TieredModalityWindowQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredModalityWindow) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [TieredModalityWindow]) -> [TieredModalityWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredModalityWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredModalityWindows(_ store: any TieredModalityWindowStore, query: TieredModalityWindowQuery) -> [TieredModalityWindow] {
        return query.apply(store.list())
    }
}
