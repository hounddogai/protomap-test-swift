import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive alert summaries by code.
    protocol AdaptiveAlertSummaryStore {
        func find(_ code: String) -> AdaptiveAlertSummary?
        func save(_ item: AdaptiveAlertSummary)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveAlertSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveAlertSummaryStore: AdaptiveAlertSummaryStore {
        var items: [String: AdaptiveAlertSummary]
        var order: [String]

        init(items: [String: AdaptiveAlertSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveAlertSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveAlertSummary) {
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

        func list() -> [AdaptiveAlertSummary] {
            var out: [AdaptiveAlertSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveAlertSummaryStore() -> any AdaptiveAlertSummaryStore {
        return MemoryAdaptiveAlertSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveAlertSummaryStore: AdaptiveAlertSummaryStore {
        var inner: MemoryAdaptiveAlertSummaryStore
        var cache: TTLCache<AdaptiveAlertSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveAlertSummaryStore, cache: TTLCache<AdaptiveAlertSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveAlertSummary? {
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

        func save(_ item: AdaptiveAlertSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveAlertSummary] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveAlertSummaryStore(_ inner: MemoryAdaptiveAlertSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveAlertSummaryStore {
        return CachedAdaptiveAlertSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive alert summaries. Empty fields match all.
    final class AdaptiveAlertSummaryQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveAlertSummary) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [AdaptiveAlertSummary]) -> [AdaptiveAlertSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveAlertSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveAlertSummaries(_ store: any AdaptiveAlertSummaryStore, query: AdaptiveAlertSummaryQuery) -> [AdaptiveAlertSummary] {
        return query.apply(store.list())
    }
}
