import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling discharge plan summaries by code.
    protocol RollingDischargePlanSummaryStore {
        func find(_ code: String) -> RollingDischargePlanSummary?
        func save(_ item: RollingDischargePlanSummary)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDischargePlanSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDischargePlanSummaryStore: RollingDischargePlanSummaryStore {
        var items: [String: RollingDischargePlanSummary]
        var order: [String]

        init(items: [String: RollingDischargePlanSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDischargePlanSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDischargePlanSummary) {
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

        func list() -> [RollingDischargePlanSummary] {
            var out: [RollingDischargePlanSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDischargePlanSummaryStore() -> any RollingDischargePlanSummaryStore {
        return MemoryRollingDischargePlanSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDischargePlanSummaryStore: RollingDischargePlanSummaryStore {
        var inner: MemoryRollingDischargePlanSummaryStore
        var cache: TTLCache<RollingDischargePlanSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDischargePlanSummaryStore, cache: TTLCache<RollingDischargePlanSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDischargePlanSummary? {
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

        func save(_ item: RollingDischargePlanSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDischargePlanSummary] {
            return inner.list()
        }
    }

    static func newCachedRollingDischargePlanSummaryStore(_ inner: MemoryRollingDischargePlanSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDischargePlanSummaryStore {
        return CachedRollingDischargePlanSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling discharge plan summaries. Empty fields match all.
    final class RollingDischargePlanSummaryQuery {
        var title: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingDischargePlanSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingDischargePlanSummary]) -> [RollingDischargePlanSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDischargePlanSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDischargePlanSummaries(_ store: any RollingDischargePlanSummaryStore, query: RollingDischargePlanSummaryQuery) -> [RollingDischargePlanSummary] {
        return query.apply(store.list())
    }
}
