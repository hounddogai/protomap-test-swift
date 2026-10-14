import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global alert summaries by code.
    protocol GlobalAlertSummaryStore {
        func find(_ code: String) -> GlobalAlertSummary?
        func save(_ item: GlobalAlertSummary)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAlertSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAlertSummaryStore: GlobalAlertSummaryStore {
        var items: [String: GlobalAlertSummary]
        var order: [String]

        init(items: [String: GlobalAlertSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAlertSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAlertSummary) {
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

        func list() -> [GlobalAlertSummary] {
            var out: [GlobalAlertSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAlertSummaryStore() -> any GlobalAlertSummaryStore {
        return MemoryGlobalAlertSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAlertSummaryStore: GlobalAlertSummaryStore {
        var inner: MemoryGlobalAlertSummaryStore
        var cache: TTLCache<GlobalAlertSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAlertSummaryStore, cache: TTLCache<GlobalAlertSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAlertSummary? {
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

        func save(_ item: GlobalAlertSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAlertSummary] {
            return inner.list()
        }
    }

    static func newCachedGlobalAlertSummaryStore(_ inner: MemoryGlobalAlertSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAlertSummaryStore {
        return CachedGlobalAlertSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global alert summaries. Empty fields match all.
    final class GlobalAlertSummaryQuery {
        var segment: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAlertSummary) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalAlertSummary]) -> [GlobalAlertSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAlertSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAlertSummaries(_ store: any GlobalAlertSummaryStore, query: GlobalAlertSummaryQuery) -> [GlobalAlertSummary] {
        return query.apply(store.list())
    }
}
