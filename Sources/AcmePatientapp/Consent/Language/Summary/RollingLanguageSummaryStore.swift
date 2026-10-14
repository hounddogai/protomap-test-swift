import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling language summaries by code.
    protocol RollingLanguageSummaryStore {
        func find(_ code: String) -> RollingLanguageSummary?
        func save(_ item: RollingLanguageSummary)
        func remove(_ code: String) -> Bool
        func list() -> [RollingLanguageSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingLanguageSummaryStore: RollingLanguageSummaryStore {
        var items: [String: RollingLanguageSummary]
        var order: [String]

        init(items: [String: RollingLanguageSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingLanguageSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingLanguageSummary) {
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

        func list() -> [RollingLanguageSummary] {
            var out: [RollingLanguageSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingLanguageSummaryStore() -> any RollingLanguageSummaryStore {
        return MemoryRollingLanguageSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingLanguageSummaryStore: RollingLanguageSummaryStore {
        var inner: MemoryRollingLanguageSummaryStore
        var cache: TTLCache<RollingLanguageSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingLanguageSummaryStore, cache: TTLCache<RollingLanguageSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingLanguageSummary? {
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

        func save(_ item: RollingLanguageSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingLanguageSummary] {
            return inner.list()
        }
    }

    static func newCachedRollingLanguageSummaryStore(_ inner: MemoryRollingLanguageSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingLanguageSummaryStore {
        return CachedRollingLanguageSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling language summaries. Empty fields match all.
    final class RollingLanguageSummaryQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingLanguageSummary) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingLanguageSummary]) -> [RollingLanguageSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingLanguageSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingLanguageSummaries(_ store: any RollingLanguageSummaryStore, query: RollingLanguageSummaryQuery) -> [RollingLanguageSummary] {
        return query.apply(store.list())
    }
}
