import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool summaries by code.
    protocol FloatPoolSummaryStore {
        func find(_ code: String) -> FloatPoolSummary?
        func save(_ item: FloatPoolSummary)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolSummaryStore: FloatPoolSummaryStore {
        var items: [String: FloatPoolSummary]
        var order: [String]

        init(items: [String: FloatPoolSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolSummary) {
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

        func list() -> [FloatPoolSummary] {
            var out: [FloatPoolSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolSummaryStore() -> any FloatPoolSummaryStore {
        return MemoryFloatPoolSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolSummaryStore: FloatPoolSummaryStore {
        var inner: MemoryFloatPoolSummaryStore
        var cache: TTLCache<FloatPoolSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolSummaryStore, cache: TTLCache<FloatPoolSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolSummary? {
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

        func save(_ item: FloatPoolSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolSummary] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolSummaryStore(_ inner: MemoryFloatPoolSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolSummaryStore {
        return CachedFloatPoolSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool summaries. Empty fields match all.
    final class FloatPoolSummaryQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FloatPoolSummary]) -> [FloatPoolSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolSummaries(_ store: any FloatPoolSummaryStore, query: FloatPoolSummaryQuery) -> [FloatPoolSummary] {
        return query.apply(store.list())
    }
}
