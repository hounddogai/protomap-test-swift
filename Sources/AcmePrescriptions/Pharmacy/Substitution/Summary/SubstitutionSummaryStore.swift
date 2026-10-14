import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution summaries by code.
    protocol SubstitutionSummaryStore {
        func find(_ code: String) -> SubstitutionSummary?
        func save(_ item: SubstitutionSummary)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionSummaryStore: SubstitutionSummaryStore {
        var items: [String: SubstitutionSummary]
        var order: [String]

        init(items: [String: SubstitutionSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionSummary) {
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

        func list() -> [SubstitutionSummary] {
            var out: [SubstitutionSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionSummaryStore() -> any SubstitutionSummaryStore {
        return MemorySubstitutionSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionSummaryStore: SubstitutionSummaryStore {
        var inner: MemorySubstitutionSummaryStore
        var cache: TTLCache<SubstitutionSummary>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionSummaryStore, cache: TTLCache<SubstitutionSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionSummary? {
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

        func save(_ item: SubstitutionSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionSummary] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionSummaryStore(_ inner: MemorySubstitutionSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionSummaryStore {
        return CachedSubstitutionSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution summaries. Empty fields match all.
    final class SubstitutionSummaryQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionSummary) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionSummary]) -> [SubstitutionSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionSummaries(_ store: any SubstitutionSummaryStore, query: SubstitutionSummaryQuery) -> [SubstitutionSummary] {
        return query.apply(store.list())
    }
}
