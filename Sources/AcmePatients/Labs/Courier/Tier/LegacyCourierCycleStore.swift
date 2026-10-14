import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy courier cycles by code.
    protocol LegacyCourierCycleStore {
        func find(_ code: String) -> LegacyCourierCycle?
        func save(_ item: LegacyCourierCycle)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCourierCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCourierCycleStore: LegacyCourierCycleStore {
        var items: [String: LegacyCourierCycle]
        var order: [String]

        init(items: [String: LegacyCourierCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCourierCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCourierCycle) {
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

        func list() -> [LegacyCourierCycle] {
            var out: [LegacyCourierCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCourierCycleStore() -> any LegacyCourierCycleStore {
        return MemoryLegacyCourierCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCourierCycleStore: LegacyCourierCycleStore {
        var inner: MemoryLegacyCourierCycleStore
        var cache: TTLCache<LegacyCourierCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCourierCycleStore, cache: TTLCache<LegacyCourierCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCourierCycle? {
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

        func save(_ item: LegacyCourierCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCourierCycle] {
            return inner.list()
        }
    }

    static func newCachedLegacyCourierCycleStore(_ inner: MemoryLegacyCourierCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCourierCycleStore {
        return CachedLegacyCourierCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy courier cycles. Empty fields match all.
    final class LegacyCourierCycleQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCourierCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCourierCycle]) -> [LegacyCourierCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCourierCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCourierCycles(_ store: any LegacyCourierCycleStore, query: LegacyCourierCycleQuery) -> [LegacyCourierCycle] {
        return query.apply(store.list())
    }
}
