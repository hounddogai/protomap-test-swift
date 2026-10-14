import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual statement rollups by code.
    protocol ManualStatementRollupStore {
        func find(_ code: String) -> ManualStatementRollup?
        func save(_ item: ManualStatementRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ManualStatementRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualStatementRollupStore: ManualStatementRollupStore {
        var items: [String: ManualStatementRollup]
        var order: [String]

        init(items: [String: ManualStatementRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualStatementRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualStatementRollup) {
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

        func list() -> [ManualStatementRollup] {
            var out: [ManualStatementRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualStatementRollupStore() -> any ManualStatementRollupStore {
        return MemoryManualStatementRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualStatementRollupStore: ManualStatementRollupStore {
        var inner: MemoryManualStatementRollupStore
        var cache: TTLCache<ManualStatementRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualStatementRollupStore, cache: TTLCache<ManualStatementRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualStatementRollup? {
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

        func save(_ item: ManualStatementRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualStatementRollup] {
            return inner.list()
        }
    }

    static func newCachedManualStatementRollupStore(_ inner: MemoryManualStatementRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualStatementRollupStore {
        return CachedManualStatementRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual statement rollups. Empty fields match all.
    final class ManualStatementRollupQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualStatementRollup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualStatementRollup]) -> [ManualStatementRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualStatementRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualStatementRollups(_ store: any ManualStatementRollupStore, query: ManualStatementRollupQuery) -> [ManualStatementRollup] {
        return query.apply(store.list())
    }
}
