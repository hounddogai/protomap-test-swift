import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global dispense summaries by code.
    protocol GlobalDispenseSummaryStore {
        func find(_ code: String) -> GlobalDispenseSummary?
        func save(_ item: GlobalDispenseSummary)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDispenseSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDispenseSummaryStore: GlobalDispenseSummaryStore {
        var items: [String: GlobalDispenseSummary]
        var order: [String]

        init(items: [String: GlobalDispenseSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDispenseSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDispenseSummary) {
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

        func list() -> [GlobalDispenseSummary] {
            var out: [GlobalDispenseSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDispenseSummaryStore() -> any GlobalDispenseSummaryStore {
        return MemoryGlobalDispenseSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDispenseSummaryStore: GlobalDispenseSummaryStore {
        var inner: MemoryGlobalDispenseSummaryStore
        var cache: TTLCache<GlobalDispenseSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDispenseSummaryStore, cache: TTLCache<GlobalDispenseSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDispenseSummary? {
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

        func save(_ item: GlobalDispenseSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDispenseSummary] {
            return inner.list()
        }
    }

    static func newCachedGlobalDispenseSummaryStore(_ inner: MemoryGlobalDispenseSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDispenseSummaryStore {
        return CachedGlobalDispenseSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global dispense summaries. Empty fields match all.
    final class GlobalDispenseSummaryQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDispenseSummary) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalDispenseSummary]) -> [GlobalDispenseSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDispenseSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDispenseSummaries(_ store: any GlobalDispenseSummaryStore, query: GlobalDispenseSummaryQuery) -> [GlobalDispenseSummary] {
        return query.apply(store.list())
    }
}
