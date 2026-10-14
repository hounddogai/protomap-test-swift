import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning rollups by code.
    protocol CleaningRollupStore {
        func find(_ code: String) -> CleaningRollup?
        func save(_ item: CleaningRollup)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningRollupStore: CleaningRollupStore {
        var items: [String: CleaningRollup]
        var order: [String]

        init(items: [String: CleaningRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningRollup) {
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

        func list() -> [CleaningRollup] {
            var out: [CleaningRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningRollupStore() -> any CleaningRollupStore {
        return MemoryCleaningRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningRollupStore: CleaningRollupStore {
        var inner: MemoryCleaningRollupStore
        var cache: TTLCache<CleaningRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningRollupStore, cache: TTLCache<CleaningRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningRollup? {
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

        func save(_ item: CleaningRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningRollup] {
            return inner.list()
        }
    }

    static func newCachedCleaningRollupStore(_ inner: MemoryCleaningRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningRollupStore {
        return CachedCleaningRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning rollups. Empty fields match all.
    final class CleaningRollupQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningRollup) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningRollup]) -> [CleaningRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningRollups(_ store: any CleaningRollupStore, query: CleaningRollupQuery) -> [CleaningRollup] {
        return query.apply(store.list())
    }
}
