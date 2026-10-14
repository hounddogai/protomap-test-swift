import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped modality windows by code.
    protocol CappedModalityWindowStore {
        func find(_ code: String) -> CappedModalityWindow?
        func save(_ item: CappedModalityWindow)
        func remove(_ code: String) -> Bool
        func list() -> [CappedModalityWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedModalityWindowStore: CappedModalityWindowStore {
        var items: [String: CappedModalityWindow]
        var order: [String]

        init(items: [String: CappedModalityWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedModalityWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedModalityWindow) {
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

        func list() -> [CappedModalityWindow] {
            var out: [CappedModalityWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedModalityWindowStore() -> any CappedModalityWindowStore {
        return MemoryCappedModalityWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedModalityWindowStore: CappedModalityWindowStore {
        var inner: MemoryCappedModalityWindowStore
        var cache: TTLCache<CappedModalityWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedModalityWindowStore, cache: TTLCache<CappedModalityWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedModalityWindow? {
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

        func save(_ item: CappedModalityWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedModalityWindow] {
            return inner.list()
        }
    }

    static func newCachedCappedModalityWindowStore(_ inner: MemoryCappedModalityWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedModalityWindowStore {
        return CachedCappedModalityWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped modality windows. Empty fields match all.
    final class CappedModalityWindowQuery {
        var region: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedModalityWindow) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedModalityWindow]) -> [CappedModalityWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedModalityWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedModalityWindows(_ store: any CappedModalityWindowStore, query: CappedModalityWindowQuery) -> [CappedModalityWindow] {
        return query.apply(store.list())
    }
}
