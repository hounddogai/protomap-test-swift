import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach summaries by code.
    protocol OutreachSummaryStore {
        func find(_ code: String) -> OutreachSummary?
        func save(_ item: OutreachSummary)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachSummaryStore: OutreachSummaryStore {
        var items: [String: OutreachSummary]
        var order: [String]

        init(items: [String: OutreachSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachSummary) {
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

        func list() -> [OutreachSummary] {
            var out: [OutreachSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachSummaryStore() -> any OutreachSummaryStore {
        return MemoryOutreachSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachSummaryStore: OutreachSummaryStore {
        var inner: MemoryOutreachSummaryStore
        var cache: TTLCache<OutreachSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachSummaryStore, cache: TTLCache<OutreachSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachSummary? {
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

        func save(_ item: OutreachSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachSummary] {
            return inner.list()
        }
    }

    static func newCachedOutreachSummaryStore(_ inner: MemoryOutreachSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachSummaryStore {
        return CachedOutreachSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach summaries. Empty fields match all.
    final class OutreachSummaryQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachSummary) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachSummary]) -> [OutreachSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachSummaries(_ store: any OutreachSummaryStore, query: OutreachSummaryQuery) -> [OutreachSummary] {
        return query.apply(store.list())
    }
}
