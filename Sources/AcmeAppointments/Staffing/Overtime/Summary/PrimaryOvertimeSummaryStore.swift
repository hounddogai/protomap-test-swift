import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary overtime summaries by code.
    protocol PrimaryOvertimeSummaryStore {
        func find(_ code: String) -> PrimaryOvertimeSummary?
        func save(_ item: PrimaryOvertimeSummary)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryOvertimeSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryOvertimeSummaryStore: PrimaryOvertimeSummaryStore {
        var items: [String: PrimaryOvertimeSummary]
        var order: [String]

        init(items: [String: PrimaryOvertimeSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryOvertimeSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryOvertimeSummary) {
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

        func list() -> [PrimaryOvertimeSummary] {
            var out: [PrimaryOvertimeSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryOvertimeSummaryStore() -> any PrimaryOvertimeSummaryStore {
        return MemoryPrimaryOvertimeSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryOvertimeSummaryStore: PrimaryOvertimeSummaryStore {
        var inner: MemoryPrimaryOvertimeSummaryStore
        var cache: TTLCache<PrimaryOvertimeSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryOvertimeSummaryStore, cache: TTLCache<PrimaryOvertimeSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryOvertimeSummary? {
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

        func save(_ item: PrimaryOvertimeSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryOvertimeSummary] {
            return inner.list()
        }
    }

    static func newCachedPrimaryOvertimeSummaryStore(_ inner: MemoryPrimaryOvertimeSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryOvertimeSummaryStore {
        return CachedPrimaryOvertimeSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary overtime summaries. Empty fields match all.
    final class PrimaryOvertimeSummaryQuery {
        var country: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryOvertimeSummary) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryOvertimeSummary]) -> [PrimaryOvertimeSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryOvertimeSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryOvertimeSummaries(_ store: any PrimaryOvertimeSummaryStore, query: PrimaryOvertimeSummaryQuery) -> [PrimaryOvertimeSummary] {
        return query.apply(store.list())
    }
}
