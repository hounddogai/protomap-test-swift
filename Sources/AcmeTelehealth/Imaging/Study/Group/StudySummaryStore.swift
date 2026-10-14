import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study summaries by code.
    protocol StudySummaryStore {
        func find(_ code: String) -> StudySummary?
        func save(_ item: StudySummary)
        func remove(_ code: String) -> Bool
        func list() -> [StudySummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudySummaryStore: StudySummaryStore {
        var items: [String: StudySummary]
        var order: [String]

        init(items: [String: StudySummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudySummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudySummary) {
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

        func list() -> [StudySummary] {
            var out: [StudySummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudySummaryStore() -> any StudySummaryStore {
        return MemoryStudySummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudySummaryStore: StudySummaryStore {
        var inner: MemoryStudySummaryStore
        var cache: TTLCache<StudySummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudySummaryStore, cache: TTLCache<StudySummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudySummary? {
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

        func save(_ item: StudySummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudySummary] {
            return inner.list()
        }
    }

    static func newCachedStudySummaryStore(_ inner: MemoryStudySummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudySummaryStore {
        return CachedStudySummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study summaries. Empty fields match all.
    final class StudySummaryQuery {
        var channel: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudySummary) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudySummary]) -> [StudySummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudySummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudySummaries(_ store: any StudySummaryStore, query: StudySummaryQuery) -> [StudySummary] {
        return query.apply(store.list())
    }
}
