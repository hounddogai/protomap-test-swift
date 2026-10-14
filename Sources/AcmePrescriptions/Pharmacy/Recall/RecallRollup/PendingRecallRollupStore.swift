import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending recall rollups by code.
    protocol PendingRecallRollupStore {
        func find(_ code: String) -> PendingRecallRollup?
        func save(_ item: PendingRecallRollup)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRecallRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRecallRollupStore: PendingRecallRollupStore {
        var items: [String: PendingRecallRollup]
        var order: [String]

        init(items: [String: PendingRecallRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRecallRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRecallRollup) {
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

        func list() -> [PendingRecallRollup] {
            var out: [PendingRecallRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRecallRollupStore() -> any PendingRecallRollupStore {
        return MemoryPendingRecallRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRecallRollupStore: PendingRecallRollupStore {
        var inner: MemoryPendingRecallRollupStore
        var cache: TTLCache<PendingRecallRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRecallRollupStore, cache: TTLCache<PendingRecallRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRecallRollup? {
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

        func save(_ item: PendingRecallRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRecallRollup] {
            return inner.list()
        }
    }

    static func newCachedPendingRecallRollupStore(_ inner: MemoryPendingRecallRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRecallRollupStore {
        return CachedPendingRecallRollupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending recall rollups. Empty fields match all.
    final class PendingRecallRollupQuery {
        var locale: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minSequence: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRecallRollup) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [PendingRecallRollup]) -> [PendingRecallRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRecallRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRecallRollups(_ store: any PendingRecallRollupStore, query: PendingRecallRollupQuery) -> [PendingRecallRollup] {
        return query.apply(store.list())
    }
}
