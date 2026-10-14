import AcmePlatform
import Foundation

extension Consent {
    /// Keeps default disclosure summaries by code.
    protocol DefaultDisclosureSummaryStore {
        func find(_ code: String) -> DefaultDisclosureSummary?
        func save(_ item: DefaultDisclosureSummary)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultDisclosureSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultDisclosureSummaryStore: DefaultDisclosureSummaryStore {
        var items: [String: DefaultDisclosureSummary]
        var order: [String]

        init(items: [String: DefaultDisclosureSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultDisclosureSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultDisclosureSummary) {
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

        func list() -> [DefaultDisclosureSummary] {
            var out: [DefaultDisclosureSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultDisclosureSummaryStore() -> any DefaultDisclosureSummaryStore {
        return MemoryDefaultDisclosureSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultDisclosureSummaryStore: DefaultDisclosureSummaryStore {
        var inner: MemoryDefaultDisclosureSummaryStore
        var cache: TTLCache<DefaultDisclosureSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultDisclosureSummaryStore, cache: TTLCache<DefaultDisclosureSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultDisclosureSummary? {
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

        func save(_ item: DefaultDisclosureSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultDisclosureSummary] {
            return inner.list()
        }
    }

    static func newCachedDefaultDisclosureSummaryStore(_ inner: MemoryDefaultDisclosureSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultDisclosureSummaryStore {
        return CachedDefaultDisclosureSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default disclosure summaries. Empty fields match all.
    final class DefaultDisclosureSummaryQuery {
        var locale: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultDisclosureSummary) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [DefaultDisclosureSummary]) -> [DefaultDisclosureSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultDisclosureSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultDisclosureSummaries(_ store: any DefaultDisclosureSummaryStore, query: DefaultDisclosureSummaryQuery) -> [DefaultDisclosureSummary] {
        return query.apply(store.list())
    }
}
