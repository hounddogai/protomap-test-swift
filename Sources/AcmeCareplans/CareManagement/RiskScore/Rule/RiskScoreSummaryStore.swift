import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score summaries by code.
    protocol RiskScoreSummaryStore {
        func find(_ code: String) -> RiskScoreSummary?
        func save(_ item: RiskScoreSummary)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreSummaryStore: RiskScoreSummaryStore {
        var items: [String: RiskScoreSummary]
        var order: [String]

        init(items: [String: RiskScoreSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreSummary) {
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

        func list() -> [RiskScoreSummary] {
            var out: [RiskScoreSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreSummaryStore() -> any RiskScoreSummaryStore {
        return MemoryRiskScoreSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreSummaryStore: RiskScoreSummaryStore {
        var inner: MemoryRiskScoreSummaryStore
        var cache: TTLCache<RiskScoreSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreSummaryStore, cache: TTLCache<RiskScoreSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreSummary? {
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

        func save(_ item: RiskScoreSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreSummary] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreSummaryStore(_ inner: MemoryRiskScoreSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreSummaryStore {
        return CachedRiskScoreSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score summaries. Empty fields match all.
    final class RiskScoreSummaryQuery {
        var category: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreSummary) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [RiskScoreSummary]) -> [RiskScoreSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreSummaries(_ store: any RiskScoreSummaryStore, query: RiskScoreSummaryQuery) -> [RiskScoreSummary] {
        return query.apply(store.list())
    }
}
