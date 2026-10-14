import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped revocation summaries by code.
    protocol CappedRevocationSummaryStore {
        func find(_ code: String) -> CappedRevocationSummary?
        func save(_ item: CappedRevocationSummary)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRevocationSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRevocationSummaryStore: CappedRevocationSummaryStore {
        var items: [String: CappedRevocationSummary]
        var order: [String]

        init(items: [String: CappedRevocationSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRevocationSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRevocationSummary) {
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

        func list() -> [CappedRevocationSummary] {
            var out: [CappedRevocationSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRevocationSummaryStore() -> any CappedRevocationSummaryStore {
        return MemoryCappedRevocationSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRevocationSummaryStore: CappedRevocationSummaryStore {
        var inner: MemoryCappedRevocationSummaryStore
        var cache: TTLCache<CappedRevocationSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRevocationSummaryStore, cache: TTLCache<CappedRevocationSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRevocationSummary? {
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

        func save(_ item: CappedRevocationSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRevocationSummary] {
            return inner.list()
        }
    }

    static func newCachedCappedRevocationSummaryStore(_ inner: MemoryCappedRevocationSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRevocationSummaryStore {
        return CachedCappedRevocationSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped revocation summaries. Empty fields match all.
    final class CappedRevocationSummaryQuery {
        var unit: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRevocationSummary) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRevocationSummary]) -> [CappedRevocationSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRevocationSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRevocationSummaries(_ store: any CappedRevocationSummaryStore, query: CappedRevocationSummaryQuery) -> [CappedRevocationSummary] {
        return query.apply(store.list())
    }
}
