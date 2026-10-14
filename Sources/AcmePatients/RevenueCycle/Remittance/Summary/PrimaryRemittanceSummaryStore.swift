import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary remittance summaries by code.
    protocol PrimaryRemittanceSummaryStore {
        func find(_ code: String) -> PrimaryRemittanceSummary?
        func save(_ item: PrimaryRemittanceSummary)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRemittanceSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRemittanceSummaryStore: PrimaryRemittanceSummaryStore {
        var items: [String: PrimaryRemittanceSummary]
        var order: [String]

        init(items: [String: PrimaryRemittanceSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRemittanceSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRemittanceSummary) {
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

        func list() -> [PrimaryRemittanceSummary] {
            var out: [PrimaryRemittanceSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRemittanceSummaryStore() -> any PrimaryRemittanceSummaryStore {
        return MemoryPrimaryRemittanceSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRemittanceSummaryStore: PrimaryRemittanceSummaryStore {
        var inner: MemoryPrimaryRemittanceSummaryStore
        var cache: TTLCache<PrimaryRemittanceSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRemittanceSummaryStore, cache: TTLCache<PrimaryRemittanceSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRemittanceSummary? {
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

        func save(_ item: PrimaryRemittanceSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRemittanceSummary] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRemittanceSummaryStore(_ inner: MemoryPrimaryRemittanceSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRemittanceSummaryStore {
        return CachedPrimaryRemittanceSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary remittance summaries. Empty fields match all.
    final class PrimaryRemittanceSummaryQuery {
        var unit: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVersion: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRemittanceSummary) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PrimaryRemittanceSummary]) -> [PrimaryRemittanceSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRemittanceSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRemittanceSummaries(_ store: any PrimaryRemittanceSummaryStore, query: PrimaryRemittanceSummaryQuery) -> [PrimaryRemittanceSummary] {
        return query.apply(store.list())
    }
}
