import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending rounding windows by code.
    protocol PendingRoundingWindowStore {
        func find(_ code: String) -> PendingRoundingWindow?
        func save(_ item: PendingRoundingWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRoundingWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRoundingWindowStore: PendingRoundingWindowStore {
        var items: [String: PendingRoundingWindow]
        var order: [String]

        init(items: [String: PendingRoundingWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRoundingWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRoundingWindow) {
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

        func list() -> [PendingRoundingWindow] {
            var out: [PendingRoundingWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRoundingWindowStore() -> any PendingRoundingWindowStore {
        return MemoryPendingRoundingWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRoundingWindowStore: PendingRoundingWindowStore {
        var inner: MemoryPendingRoundingWindowStore
        var cache: TTLCache<PendingRoundingWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRoundingWindowStore, cache: TTLCache<PendingRoundingWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRoundingWindow? {
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

        func save(_ item: PendingRoundingWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRoundingWindow] {
            return inner.list()
        }
    }

    static func newCachedPendingRoundingWindowStore(_ inner: MemoryPendingRoundingWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRoundingWindowStore {
        return CachedPendingRoundingWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending rounding windows. Empty fields match all.
    final class PendingRoundingWindowQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRoundingWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRoundingWindow]) -> [PendingRoundingWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRoundingWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRoundingWindows(_ store: any PendingRoundingWindowStore, query: PendingRoundingWindowQuery) -> [PendingRoundingWindow] {
        return query.apply(store.list())
    }
}
