import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual goal summaries by code.
    protocol ManualGoalSummaryStore {
        func find(_ code: String) -> ManualGoalSummary?
        func save(_ item: ManualGoalSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ManualGoalSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualGoalSummaryStore: ManualGoalSummaryStore {
        var items: [String: ManualGoalSummary]
        var order: [String]

        init(items: [String: ManualGoalSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualGoalSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualGoalSummary) {
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

        func list() -> [ManualGoalSummary] {
            var out: [ManualGoalSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualGoalSummaryStore() -> any ManualGoalSummaryStore {
        return MemoryManualGoalSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualGoalSummaryStore: ManualGoalSummaryStore {
        var inner: MemoryManualGoalSummaryStore
        var cache: TTLCache<ManualGoalSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualGoalSummaryStore, cache: TTLCache<ManualGoalSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualGoalSummary? {
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

        func save(_ item: ManualGoalSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualGoalSummary] {
            return inner.list()
        }
    }

    static func newCachedManualGoalSummaryStore(_ inner: MemoryManualGoalSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualGoalSummaryStore {
        return CachedManualGoalSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual goal summaries. Empty fields match all.
    final class ManualGoalSummaryQuery {
        var region: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVersion: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualGoalSummary) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualGoalSummary]) -> [ManualGoalSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualGoalSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualGoalSummaries(_ store: any ManualGoalSummaryStore, query: ManualGoalSummaryQuery) -> [ManualGoalSummary] {
        return query.apply(store.list())
    }
}
