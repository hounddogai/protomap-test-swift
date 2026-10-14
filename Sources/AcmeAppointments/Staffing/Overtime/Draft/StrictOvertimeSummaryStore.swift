import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict overtime summaries by code.
    protocol StrictOvertimeSummaryStore {
        func find(_ code: String) -> StrictOvertimeSummary?
        func save(_ item: StrictOvertimeSummary)
        func remove(_ code: String) -> Bool
        func list() -> [StrictOvertimeSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictOvertimeSummaryStore: StrictOvertimeSummaryStore {
        var items: [String: StrictOvertimeSummary]
        var order: [String]

        init(items: [String: StrictOvertimeSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictOvertimeSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictOvertimeSummary) {
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

        func list() -> [StrictOvertimeSummary] {
            var out: [StrictOvertimeSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictOvertimeSummaryStore() -> any StrictOvertimeSummaryStore {
        return MemoryStrictOvertimeSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictOvertimeSummaryStore: StrictOvertimeSummaryStore {
        var inner: MemoryStrictOvertimeSummaryStore
        var cache: TTLCache<StrictOvertimeSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictOvertimeSummaryStore, cache: TTLCache<StrictOvertimeSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictOvertimeSummary? {
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

        func save(_ item: StrictOvertimeSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictOvertimeSummary] {
            return inner.list()
        }
    }

    static func newCachedStrictOvertimeSummaryStore(_ inner: MemoryStrictOvertimeSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictOvertimeSummaryStore {
        return CachedStrictOvertimeSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict overtime summaries. Empty fields match all.
    final class StrictOvertimeSummaryQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictOvertimeSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictOvertimeSummary]) -> [StrictOvertimeSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictOvertimeSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictOvertimeSummaries(_ store: any StrictOvertimeSummaryStore, query: StrictOvertimeSummaryQuery) -> [StrictOvertimeSummary] {
        return query.apply(store.list())
    }
}
