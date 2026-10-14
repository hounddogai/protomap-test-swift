import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending cleaning windows by code.
    protocol PendingCleaningWindowStore {
        func find(_ code: String) -> PendingCleaningWindow?
        func save(_ item: PendingCleaningWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCleaningWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCleaningWindowStore: PendingCleaningWindowStore {
        var items: [String: PendingCleaningWindow]
        var order: [String]

        init(items: [String: PendingCleaningWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCleaningWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCleaningWindow) {
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

        func list() -> [PendingCleaningWindow] {
            var out: [PendingCleaningWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCleaningWindowStore() -> any PendingCleaningWindowStore {
        return MemoryPendingCleaningWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCleaningWindowStore: PendingCleaningWindowStore {
        var inner: MemoryPendingCleaningWindowStore
        var cache: TTLCache<PendingCleaningWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCleaningWindowStore, cache: TTLCache<PendingCleaningWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCleaningWindow? {
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

        func save(_ item: PendingCleaningWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCleaningWindow] {
            return inner.list()
        }
    }

    static func newCachedPendingCleaningWindowStore(_ inner: MemoryPendingCleaningWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCleaningWindowStore {
        return CachedPendingCleaningWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending cleaning windows. Empty fields match all.
    final class PendingCleaningWindowQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCleaningWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCleaningWindow]) -> [PendingCleaningWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCleaningWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCleaningWindows(_ store: any PendingCleaningWindowStore, query: PendingCleaningWindowQuery) -> [PendingCleaningWindow] {
        return query.apply(store.list())
    }
}
