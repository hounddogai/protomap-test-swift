import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default care protocol summaries by code.
    protocol DefaultCareProtocolSummaryStore {
        func find(_ code: String) -> DefaultCareProtocolSummary?
        func save(_ item: DefaultCareProtocolSummary)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCareProtocolSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCareProtocolSummaryStore: DefaultCareProtocolSummaryStore {
        var items: [String: DefaultCareProtocolSummary]
        var order: [String]

        init(items: [String: DefaultCareProtocolSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCareProtocolSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCareProtocolSummary) {
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

        func list() -> [DefaultCareProtocolSummary] {
            var out: [DefaultCareProtocolSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCareProtocolSummaryStore() -> any DefaultCareProtocolSummaryStore {
        return MemoryDefaultCareProtocolSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCareProtocolSummaryStore: DefaultCareProtocolSummaryStore {
        var inner: MemoryDefaultCareProtocolSummaryStore
        var cache: TTLCache<DefaultCareProtocolSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCareProtocolSummaryStore, cache: TTLCache<DefaultCareProtocolSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCareProtocolSummary? {
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

        func save(_ item: DefaultCareProtocolSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCareProtocolSummary] {
            return inner.list()
        }
    }

    static func newCachedDefaultCareProtocolSummaryStore(_ inner: MemoryDefaultCareProtocolSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCareProtocolSummaryStore {
        return CachedDefaultCareProtocolSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default care protocol summaries. Empty fields match all.
    final class DefaultCareProtocolSummaryQuery {
        var facility: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minAmount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCareProtocolSummary) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [DefaultCareProtocolSummary]) -> [DefaultCareProtocolSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCareProtocolSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCareProtocolSummaries(_ store: any DefaultCareProtocolSummaryStore, query: DefaultCareProtocolSummaryQuery) -> [DefaultCareProtocolSummary] {
        return query.apply(store.list())
    }
}
