import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff summaries by code.
    protocol HandoffSummaryStore {
        func find(_ code: String) -> HandoffSummary?
        func save(_ item: HandoffSummary)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffSummaryStore: HandoffSummaryStore {
        var items: [String: HandoffSummary]
        var order: [String]

        init(items: [String: HandoffSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffSummary) {
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

        func list() -> [HandoffSummary] {
            var out: [HandoffSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffSummaryStore() -> any HandoffSummaryStore {
        return MemoryHandoffSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffSummaryStore: HandoffSummaryStore {
        var inner: MemoryHandoffSummaryStore
        var cache: TTLCache<HandoffSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffSummaryStore, cache: TTLCache<HandoffSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffSummary? {
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

        func save(_ item: HandoffSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffSummary] {
            return inner.list()
        }
    }

    static func newCachedHandoffSummaryStore(_ inner: MemoryHandoffSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffSummaryStore {
        return CachedHandoffSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff summaries. Empty fields match all.
    final class HandoffSummaryQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [HandoffSummary]) -> [HandoffSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffSummaries(_ store: any HandoffSummaryStore, query: HandoffSummaryQuery) -> [HandoffSummary] {
        return query.apply(store.list())
    }
}
