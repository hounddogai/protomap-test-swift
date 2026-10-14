import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual closure rollups by code.
    protocol ManualClosureRollupStore {
        func find(_ code: String) -> ManualClosureRollup?
        func save(_ item: ManualClosureRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ManualClosureRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualClosureRollupStore: ManualClosureRollupStore {
        var items: [String: ManualClosureRollup]
        var order: [String]

        init(items: [String: ManualClosureRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualClosureRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualClosureRollup) {
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

        func list() -> [ManualClosureRollup] {
            var out: [ManualClosureRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualClosureRollupStore() -> any ManualClosureRollupStore {
        return MemoryManualClosureRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualClosureRollupStore: ManualClosureRollupStore {
        var inner: MemoryManualClosureRollupStore
        var cache: TTLCache<ManualClosureRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualClosureRollupStore, cache: TTLCache<ManualClosureRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualClosureRollup? {
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

        func save(_ item: ManualClosureRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualClosureRollup] {
            return inner.list()
        }
    }

    static func newCachedManualClosureRollupStore(_ inner: MemoryManualClosureRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualClosureRollupStore {
        return CachedManualClosureRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual closure rollups. Empty fields match all.
    final class ManualClosureRollupQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualClosureRollup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ManualClosureRollup]) -> [ManualClosureRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualClosureRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualClosureRollups(_ store: any ManualClosureRollupStore, query: ManualClosureRollupQuery) -> [ManualClosureRollup] {
        return query.apply(store.list())
    }
}
